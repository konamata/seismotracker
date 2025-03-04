package main

import (
	"compress/gzip"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math"
	"net/http"
	"os"
	"strings"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib" // PostgreSQL Driver
)

// timeLayout is the expected time format for the QuakeLink API.
const timeLayout = "2006,1,2,15,4,5,999999"

// Energy calculates the energy of an earthquake based on its magnitude.
func Energy(M float64) float64 {
	return math.Pow(10, 4.8+1.5*M)
}

// ResponseData represents the response structure from the QuakeLink API.
type ResponseData struct {
	Seiscomp struct {
		Events     []Event `json:"events"`
		LastUpdate string  `json:"lastUpdate"`
	} `json:"seiscomp"`
}

// Event represents a single event returned by the API.
type Event struct {
	EventID string  `json:"eventID"`
	Otime   string  `json:"otime"`
	Updated string  `json:"updated"`
	Mag     float64 `json:"mag"`
	MagType string  `json:"magType"`
	Lat     float64 `json:"lat"`
	Lon     float64 `json:"lon"`
	Depth   float64 `json:"depth"`
	Agency  string  `json:"agency"`
	Status  string  `json:"status"`
	Estatus string  `json:"estatus"`
	Emode   string  `json:"emode"`
	Felt    bool    `json:"felt"`
	Region  string  `json:"region"`
}

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	client := &http.Client{}
	lastFetched := fmt.Sprintf("%d,1,1,0,0,0,0", time.Now().Year())

	postgresURI := os.Getenv("POSTGRES_URI")
	if postgresURI == "" {
		postgresURI = "postgres://postgres:password@localhost:5432/seismotracker?sslmode=disable"
	}

	db, err := sql.Open("pgx", postgresURI)
	if err != nil {
		log.Fatalf("Failed to connect to PostgreSQL: %v", err)
	}
	defer db.Close()
	log.Println("Successfully connected to PostgreSQL.")

	if err != nil {
		log.Fatalf("Database setup failed: %v", err)
	}

	for {
		parsedLast, err := time.Parse(timeLayout, lastFetched)
		if err != nil {
			parsedLast = time.Now().UTC()
		}

		lowerBoundTime := parsedLast.Add(-1 * time.Hour)
		lowerBoundStr := lowerBoundTime.Format(timeLayout)
		upperBoundTime := time.Now().UTC()
		upperBoundStr := upperBoundTime.Format(timeLayout)

		payload := fmt.Sprintf("(updated>=%s) and updated<=%s", lowerBoundStr, upperBoundStr)
		log.Println("Sending payload:", payload)

		data, err := fetchEvents(client, payload)
		if err != nil {
			log.Printf("Error fetching events: %v", err)
			time.Sleep(30 * time.Second)
			continue
		}

		if len(data.Seiscomp.Events) > 0 {
			log.Printf("Found %d new events.", len(data.Seiscomp.Events))
			for _, event := range data.Seiscomp.Events {
				if err := upsertEvent(db, event); err != nil {
					log.Printf("Error updating PostgreSQL for event %s: %v", event.EventID, err)
				} else {
					log.Printf("EventID %s successfully inserted/updated in PostgreSQL.", event.EventID)
				}
			}
		} else {
			log.Println("No new events found.")
		}

		lastFetched = upperBoundStr
		log.Println("Updated lastFetched to:", lastFetched)

		time.Sleep(30 * time.Second)
	}
}

// fetchEvents fetches earthquake data from the API.
func fetchEvents(client *http.Client, payload string) (*ResponseData, error) {
	req, err := http.NewRequest("POST", "https://quakelink.raspberryshake.org/events/query", io.NopCloser(strings.NewReader(payload)))
	if err != nil {
		return nil, fmt.Errorf("error creating request: %w", err)
	}
	req.Header.Set("Content-Type", "text/plain")

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("error sending request: %w", err)
	}
	defer resp.Body.Close()

	var reader io.Reader = resp.Body
	if resp.Header.Get("Content-Encoding") == "gzip" {
		gz, err := gzip.NewReader(resp.Body)
		if err != nil {
			return nil, fmt.Errorf("error decompressing gzip response: %w", err)
		}
		defer gz.Close()
		reader = gz
	}

	var data ResponseData
	dec := json.NewDecoder(reader)
	if err := dec.Decode(&data); err != nil {
		return nil, fmt.Errorf("error decoding JSON: %w", err)
	}

	return &data, nil
}

// upsertEvent inserts or updates the event in PostgreSQL.
func upsertEvent(db *sql.DB, event Event) error {
	query := `
		INSERT INTO events (event_id, otime, updated, mag, mag_type, lat, lon, depth, agency, status, estatus, emode, felt, region, etldate)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
		ON CONFLICT (event_id) DO UPDATE 
		SET updated = EXCLUDED.updated, 
			mag = EXCLUDED.mag,
			mag_type = EXCLUDED.mag_type,
			lat = EXCLUDED.lat,
			lon = EXCLUDED.lon,
			depth = EXCLUDED.depth,
			agency = EXCLUDED.agency,
			status = EXCLUDED.status,
			estatus = EXCLUDED.estatus,
			emode = EXCLUDED.emode,
			felt = EXCLUDED.felt,
			region = EXCLUDED.region,
			etldate = EXCLUDED.etldate;
		`
	_, err := db.Exec(query, event.EventID, event.Otime, event.Updated, event.Mag, event.MagType, event.Lat, event.Lon, event.Depth,
		event.Agency, event.Status, event.Estatus, event.Emode, event.Felt, event.Region, time.Now().UTC())
	return err
}
