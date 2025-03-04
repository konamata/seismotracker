package db

import (
	"log"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDB() {
	postgresURI := os.Getenv("POSTGRES_URI")
	if postgresURI == "" {
		postgresURI = "postgres://postgres:password@localhost:5432/seismotracker?sslmode=disable"
	}

	var err error
	DB, err = gorm.Open(postgres.Open(postgresURI), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to the database:", err)
	}
}
