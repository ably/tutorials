#include <SPI.h>
#include <MFRC522.h>
#include <ESP8266WiFi.h>
#include <MQTT.h>

#define RST_PIN   4     // Configurable as per the IoT board
#define SS_PIN    5    // Configurable as per the IoT board
 
const char ssid[] = "<YOUR WIFI NAME>";
const char pass[] = "<YOUR WIFI PASSWORD>";

// Create MFRC522 instance
MFRC522 mfrc522(SS_PIN, RST_PIN);  
WiFiClientSecure net;
MQTTClient client;

void setup() {
    Serial.begin(9600);  // Initialize serial communications with the PC
    SPI.begin();         // Init SPI bus
    mfrc522.PCD_Init();  // Init MFRC522 card
    WiFi.begin(ssid, pass); // Init WiFi library's network settings
    client.begin("mqtt.ably.io", 8883, net); // Init communication with the MQTT broker
    client.setOptions(30, true, 1000); // Set client options: int keepAlive, bool cleanSession, int timeout
    connect(); // Call a function to establish connection with the WiFi and the MQTT broker
}

void connect() {
    Serial.print("Connecting to WiFi..."); // Helpful log in the serial monitor
    while (WiFi.status() != WL_CONNECTED) { //Check if the WiFi is connected yet, print a series of dots until it is
    Serial.print(".");
    delay(1000);
    }
    Serial.print("\nConnecting to Ably MQTT broker...");
    while (!client.connect("<YOUR-CLIENT-ID>", "<FIRST-HALF-OF-YOUR-ABLY-API-KEY>", "<SECOND-HALF-OF-YOUR-ABLY-API-KEY>")) {
    Serial.print("."); //Print dots in the serial monitor while it connects to the Ably MQTT broker
    delay(1000);
    }
    Serial.println("\nCnnected to Ably MQTT broker!");
}


void loop() {
    client.loop(); // This function returns a boolean that indicates if the loop has been successful
    delay(1000);
    // check if card is detected
    if ( ! mfrc522.PICC_IsNewCardPresent() || ! mfrc522.PICC_ReadCardSerial() ) {
    return;
    }
    Serial.println("Card detected!"); //Print to the serial monitor when a card is detected
    char UIDstr[32] = "";
    array_to_string(mfrc522.uid.uidByte, mfrc522.uid.size, UIDstr); // call a method to convert byte array to array_to_string
    // check which employee the UID belongs to
    if( UIDstr == "<YOUR-CARDS-UID>"){ 
    client.publish("standup", "Srushtika"); // publish the name of the employee to the standup channel on Ably
    delay(10000); // prevent multiple publishes by delaying the return to the loop.
    return;
    }
}
//method to convert a byte array to a string
void array_to_string(byte array[], unsigned int len, char buffer[]){
    for (unsigned int i = 0; i < len; i++){
        byte nib1 = (array[i] >> 4) & 0x0F;
        byte nib2 = (array[i] >> 0) & 0x0F;
        buffer[i*2+0] = nib1  < 0xA ? '0' + nib1  : 'A' + nib1  - 0xA;
        buffer[i*2+1] = nib2  < 0xA ? '0' + nib2  : 'A' + nib2  - 0xA;
    }
    buffer[len*2] = '\0';
}