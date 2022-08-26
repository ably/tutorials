package main

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/ably/ably-go/ably"
)

type Location struct {
	Latitude  string
	Longitude string
	Proximity float32
}

func main() {
	// connect to Ably
	client, conErr := ably.NewRealtime(ably.WithKey("YOUR_ABLY_API_KEY"))
	if conErr != nil {
		conErr = fmt.Errorf("error connecting to Ably: %w", conErr)
		fmt.Println(conErr)
	}

	// get a reference to the 'location' channel
	channel := client.Channels.Get("location")

	// subsribe to all messages on the 'location' channel
	_, subErr := channel.SubscribeAll(context.Background(), func(msg *ably.Message) {
		var location Location
		if loc, ok := msg.Data.(string); ok {
			json.Unmarshal([]byte(loc), &location)
			proximityPercent := location.Proximity * 100
			fmt.Printf("Latitude: %v, Longitude: %v, Proximity: %v %%", location.Latitude, location.Longitude, proximityPercent)
		} else {
			fmt.Printf("cannot parse input data")
		}
	})
	if subErr != nil {
		subErr := fmt.Errorf("error subscribing to channel: %w", subErr)
		fmt.Println(subErr)
	}

	// publish current coordinate to 'location' channel, as an 'update'
	pubErr := channel.Publish(context.Background(), "update", `{"latitude": "51.509865", "longitude": "-0.118092", "proximity": 0.51}`)
	if pubErr != nil {
		pubErr = fmt.Errorf("error publishing to channel: %w", pubErr)
		fmt.Println(pubErr)
	}

	// allow the publish/subscribe step to finish before exiting program
	time.Sleep(time.Second)
}
