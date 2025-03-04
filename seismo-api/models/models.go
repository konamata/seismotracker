package models

import "time"

type Event struct {
	EventID      string    `json:"event_id" gorm:"column:event_id"`
	Otime        time.Time `json:"otime" gorm:"column:otime"`
	Lat          float64   `json:"lat" gorm:"column:lat"`
	Lon          float64   `json:"lon" gorm:"column:lon"`
	Mag          float64   `json:"mag" gorm:"column:mag"`
	Depth        float64   `json:"depth" gorm:"column:depth"`
	Region       string    `json:"region" gorm:"column:region"`
	CountryName  string    `json:"country_name" gorm:"column:country_name"`
	NearestPlace string    `json:"nearest_place" gorm:"column:nearest_place"`
}
