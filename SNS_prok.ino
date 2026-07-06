#include <WiFi.h>
#include <LiquidCrystal.h>

// --- CONFIGURATION ---
const char* ssid = "1xe";         // <-- Your WiFi Name
const char* password = "spit@123"; // <-- Your WiFi Password
const int tcpPort = 8080;

// --- PIN DEFINITIONS ---
const int redLed1 = 2;
const int greenLed1 = 4;
const int redLed2 = 5;
const int greenLed2 = 18;
const int blueLed1 = 19;
const int buttonPin = 23; // <-- NEW BUTTON PIN

// Initialize the LiquidCrystal library with the ESP32 pins
LiquidCrystal lcd(12, 14, 27, 26, 25, 33);

// Create a WiFiServer and WiFiClient object
WiFiServer server(tcpPort);
WiFiClient client;

// --- NEW STATE VARIABLE ---
bool wifiStarted = false;

// --- NEW FUNCTION to start Wi-Fi ---
// This contains your original setup logic
void startWifiAndServer() {
  Serial.println("Button pressed! Starting Wi-Fi...");
  delay(100);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Connecting to");
  lcd.setCursor(0, 1);
  lcd.print(ssid);

  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    lcd.print("."); // Add visual feedback
  }
  Serial.println("\nWiFi Connected!");

  // Start the TCP server
  server.begin();

  // Display the ESP32's IP address and status
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("My IP Address:");
  lcd.setCursor(0, 1);
  lcd.print(WiFi.localIP());
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
  Serial.printf("TCP Server started on port %d\n", tcpPort);

  // Wait a moment, then show listening status
  delay(3000);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("TCP Server On");
  lcd.setCursor(0, 1);
  lcd.print("Waiting for client");
}


void setup() {
  Serial.begin(115200);

  // --- Initialize all your pins ---
  pinMode(buttonPin, INPUT_PULLUP); // Button pin
  pinMode(redLed1, OUTPUT);         // LED pins
  pinMode(greenLed1, OUTPUT);
  pinMode(redLed2, OUTPUT);
  pinMode(greenLed2, OUTPUT);
  pinMode(blueLed1, OUTPUT);

  // --- Show Welcome Message on Boot ---
  lcd.begin(16, 2);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Welcome to our"); // Fits 16 chars
  lcd.setCursor(0, 1);
  lcd.print("project");
  
  delay(2500); // Show for 2.5 seconds

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Click to proceed");
}

void loop() {
  
  // --- STATE 1: WAITING FOR BUTTON ---
  if (wifiStarted == false) {
    // Check if the button is pressed
    // (LOW because we use INPUT_PULLUP)
    if (digitalRead(buttonPin) == LOW) {
      delay(50); // Simple debounce
      if (digitalRead(buttonPin) == LOW) {
        wifiStarted = true;   // Change state
        startWifiAndServer(); // Run the Wi-Fi setup
      }
    }
  } 
  // --- STATE 2: SERVER RUNNING ---
  else {
    // This is your original loop code, unchanged
    client = server.available();

    if (client) {
      Serial.println("Client connected!");
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Client Connected");

      while (client.connected()) {
        if (client.available()) {
          String genre = client.readStringUntil('\r');
          Serial.print("Received genre: ");
          Serial.println(genre);

          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Predicted Genre:");
          lcd.setCursor(0, 1);
          lcd.print(genre);

          // Turn off all LEDs first
          digitalWrite(redLed1, LOW);
          digitalWrite(greenLed1, LOW);
          digitalWrite(redLed2, LOW);
          digitalWrite(greenLed2, LOW);
          digitalWrite(blueLed1, LOW);

          // Light up the correct LED
          if (genre == "Metal") {
            digitalWrite(redLed1, HIGH);
          } else if (genre == "Rock") {
            digitalWrite(greenLed2, HIGH);
          }
          // You can add more 'else if' for other genres and LEDs
          else {
            // e.g. light up a default/error LED?
            digitalWrite(blueLed1, HIGH); // Example
          }

          client.stop();
          Serial.println("Client disconnected. Halting until reset.");

          // Halt until reset
          while (true) {
            delay(1000);
          }
        }
      }
    }
  }
}