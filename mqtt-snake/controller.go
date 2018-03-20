package main
import (
  "fmt"
  MQTT "github.com/eclipse/paho.mqtt.golang"
  termbox "github.com/nsf/termbox-go"
)

func main() {
  options := MQTT.NewClientOptions();
  options.AddBroker("ssl://mqtt.ably.io:8883")
  options.SetKeepAlive(15)
  options.SetUsername("FIRST_HALF_OF_API_KEY")
  options.SetPassword("SECOND_HALF_OF_API_KEY")
  client := MQTT.NewClient(options)
  if token := client.Connect(); token.Wait() && token.Error() != nil {
    panic(token.Error())
  } else {
    fmt.Println("Connected!")
  }
}