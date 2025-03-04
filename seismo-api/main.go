package main

import (
	"log"

	"github.com/konamata/seismotracker/seismo-api/db"
	"github.com/konamata/seismotracker/seismo-api/handlers"

	"github.com/gin-gonic/gin"
)

func main() {
	db.ConnectDB()

	r := gin.Default()

	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		c.Next()
	})

	r.GET("/api/earthquakes", handlers.GetEarthquakes)

	log.Println("Server running on port 8080")
	r.Run(":8080")
}
