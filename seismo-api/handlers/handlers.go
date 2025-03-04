package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/konamata/seismotracker/seismo-api/db"
	"github.com/konamata/seismotracker/seismo-api/models"
)

func GetEarthquakes(c *gin.Context) {
	var events []models.Event
	startDate := time.Now().AddDate(0, 0, -1).Format("2006-01-02")
	latMin := c.Query("lat_min")
	latMax := c.Query("lat_max")
	lonMin := c.Query("lon_min")
	lonMax := c.Query("lon_max")

	// Sorgu
	result := db.DB.Table("analytics.events").
		Where("otime >= ?", startDate).
		Where("lat BETWEEN ? AND ?", latMin, latMax).
		Where("lon BETWEEN ? AND ?", lonMin, lonMax).
		Find(&events)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, events)
}
