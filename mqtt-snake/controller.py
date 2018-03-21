import paho.mqtt.client as mqtt
import curses

def on_connect(client, userdata, flags, rc):
  print('Connected')
def on_disconnect(client, userdata, rc):
  print('Disconnected')
  client.loop_stop()
client = mqtt.Client()
client.username_pw_set('FIRST_HALF_OF_API_KEY', 'SECOND_HALF_OF_API_KEY')
client.tls_set()
client.on_connect = on_connect
client.on_disconnect = on_disconnect
client.loop_start()
client.connect('mqtt.ably.io', port=8883, keepalive=15)
