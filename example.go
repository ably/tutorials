package main

import "fmt"
import "github.com/ably/ably-go/ably"

func main() {
	client, err := ably.NewRealtimeClient(ably.WithKey("INSERT-YOUR-API-KEY-HERE"))
	if err != nil {
		panic(err)
	}
}
