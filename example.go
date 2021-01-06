package main

import "fmt"
import "github.com/ably/ably-go/ably"

func main() {
	client, err := ably.NewRealtimeClient(ably.WithKey("INSERT-YOUR-API-KEY-HERE"))
	if err != nil {
		panic(err)
	}

	channel := client.Channels.Get("sport")

	_, err := channel.SubscribeAll(context.Background(), func(msg *ably.Message) {
		fmt.Printf("Received message with data '%v'\n", msg.Data)
	})
	if err != nil {
		err := fmt.Errorf("subscribing to channel: %w", err)
		fmt.Println(err)
	}

	res, err := channel.Publish("team", "Man United")
	// await confirmation of publish
	if err = res.Wait(); err != nil {
		panic(err)
	}
}
