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

  err := termbox.Init()
  if err != nil {
    panic(err)
  }
  defer termbox.Close()
  fmt.Println("Press the ESC button to quit")
  for {
    switch termbox.PollEvent().Key {
      case termbox.KeyEsc:
        client.Disconnect(0)
        return
      case termbox.KeySpace:
        fmt.Println("Space")
      case termbox.KeyArrowUp:
        fmt.Println("Up")
      case termbox.KeyArrowDown:
        fmt.Println("Down")
      case termbox.KeyArrowLeft:
        fmt.Println("Left")
      case termbox.KeyArrowRight:
        fmt.Println("Right")
    }
  }
}