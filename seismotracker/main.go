package main

import (
	"compress/gzip"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math"
	"net/http"
	"os"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
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
	EventID      string    `json:"eventID" bson:"eventID"`
	Otime        string    `json:"otime" bson:"otime"`
	Updated      string    `json:"updated" bson:"updated"`
	Mag          float64   `json:"mag" bson:"mag"`
	MagType      string    `json:"magType" bson:"magType"`
	Lat          float64   `json:"lat" bson:"lat"`
	Lon          float64   `json:"lon" bson:"lon"`
	Depth        float64   `json:"depth" bson:"depth"`
	Agency       string    `json:"agency" bson:"agency"`
	Status       string    `json:"status" bson:"status"`
	Estatus      string    `json:"estatus" bson:"estatus"`
	Emode        string    `json:"emode" bson:"emode"`
	Felt         bool      `json:"felt" bson:"felt"`
	Region       string    `json:"region" bson:"region"`
	ComputedDate time.Time `bson:"computedDate"`
	Energy       float64   `bson:"energy"`
}

func main() {
	// Set up the log flags to include date, time, and file info.
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// Create an HTTP client for reuse.
	client := &http.Client{}

	// Initialize the lastFetched timestamp.
	lastFetched := "2025,1,1,0,0,0,0"

	// Retrieve MongoDB URI from environment variable, or use the default.
	mongoURI := os.Getenv("MONGO_URI")
	if mongoURI == "" {
		mongoURI = "mongodb://root:endoplazmikretikulum@localhost:27017"
	}

	// Create a context with a 10-second timeout for connecting to MongoDB.
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Connect to MongoDB.
	mongoClient, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatalf("Failed to connect to MongoDB: %v", err)
	}
	log.Println("Successfully connected to MongoDB.")

	collection := mongoClient.Database("quakelink").Collection("events")

	// Create a unique index on the eventID field.
	indexModel := mongo.IndexModel{
		Keys:    bson.D{{Key: "eventID", Value: 1}},
		Options: options.Index().SetUnique(true),
	}
	if _, err := collection.Indexes().CreateOne(ctx, indexModel); err != nil {
		log.Fatalf("Failed to create unique index on eventID: %v", err)
	}
	log.Println("Successfully created unique index on eventID.")

	// Continuously fetch events from the API and update MongoDB.
	for {
		// Parse the lastFetched time.
		parsedLast, err := time.Parse(timeLayout, lastFetched)
		if err != nil {
			// If parsing fails, use the current UTC time.
			parsedLast = time.Now().UTC()
		}

		// Calculate the lower bound by subtracting one hour from lastFetched.
		lowerBoundTime := parsedLast.Add(-1 * time.Hour)
		lowerBoundStr := lowerBoundTime.Format(timeLayout)

		// Upper bound is the current UTC time.
		upperBoundTime := time.Now().UTC()
		upperBoundStr := upperBoundTime.Format(timeLayout)

		// Build the query payload.
		payload := fmt.Sprintf("(updated>=%s) and updated<=%s", lowerBoundStr, upperBoundStr)
		log.Println("Sending payload:", payload)

		// Fetch events from the API.
		data, err := fetchEvents(client, payload)
		if err != nil {
			log.Printf("Error fetching events: %v", err)
			time.Sleep(30 * time.Second)
			continue
		}

		// Process and upsert events in MongoDB.
		if len(data.Seiscomp.Events) > 0 {
			log.Printf("Found %d new events.", len(data.Seiscomp.Events))
			for _, event := range data.Seiscomp.Events {
				// Parse the event time (otime) into a time.Time object.
				computedDate, err := time.Parse(time.RFC3339, event.Otime)
				if err != nil {
					log.Printf("Error parsing otime for event %s: %v", event.EventID, err)
					continue
				}
				event.ComputedDate = computedDate

				// Calculate the energy of the earthquake.
				event.Energy = Energy(event.Mag)

				// Insert or update the event in MongoDB.
				if err := upsertEvent(collection, event); err != nil {
					log.Printf("Error updating MongoDB for event %s: %v", event.EventID, err)
				} else {
					log.Printf("EventID %s successfully inserted/updated in MongoDB.", event.EventID)
				}
			}
		} else {
			log.Println("No new events found.")
		}

		// Update lastFetched to the current upper bound.
		lastFetched = upperBoundStr
		log.Println("Updated lastFetched to:", lastFetched)

		time.Sleep(30 * time.Second)
	}
}

// fetchEvents makes a POST request to the QuakeLink API with the given payload,
// uses streaming JSON decoding to minimize memory usage, and returns the parsed data.
func fetchEvents(client *http.Client, payload string) (*ResponseData, error) {
	// Create a new POST request.
	req, err := http.NewRequest("POST", "https://quakelink.raspberryshake.org/events/query", io.NopCloser(strings.NewReader(payload)))
	if err != nil {
		return nil, fmt.Errorf("error creating request: %w", err)
	}
	req.Header.Set("Content-Type", "text/plain")

	// Send the request.
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("error sending request: %w", err)
	}
	defer func(Body io.ReadCloser) {
		err := Body.Close()
		if err != nil {
			log.Printf("Error closing response body: %v", err)
		}
	}(resp.Body)

	// Use gzip reader if the response is compressed.
	var reader io.Reader = resp.Body
	if resp.Header.Get("Content-Encoding") == "gzip" {
		gz, err := gzip.NewReader(resp.Body)
		if err != nil {
			return nil, fmt.Errorf("error decompressing gzip response: %w", err)
		}
		defer func(gz *gzip.Reader) {
			err := gz.Close()
			if err != nil {
				log.Printf("Error closing gzip reader: %v", err)
			}
		}(gz)
		reader = gz
	}

	// Stream decode the JSON response.
	var data ResponseData
	dec := json.NewDecoder(reader)
	if err := dec.Decode(&data); err != nil {
		return nil, fmt.Errorf("error decoding JSON: %w", err)
	}

	return &data, nil
}

// upsertEvent inserts or updates the event in MongoDB based on its eventID.
func upsertEvent(collection *mongo.Collection, event Event) error {
	filter := bson.M{"eventID": event.EventID}
	update := bson.M{"$set": event}

	// Create a context with a 5-second timeout for the MongoDB operation.
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := collection.UpdateOne(ctx, filter, update, options.Update().SetUpsert(true))
	return err
}
