#include <Servo.h>
#include <Wire.h> 
#include <LiquidCrystal_I2C.h>

#define trigPin 9
#define echoPin 10
#define joyX A0
#define buzzerPin 3
#define lockThreshold 40
#define dangerThreshold 10

LiquidCrystal_I2C lcd(0x27, 16, 2); 
Servo myservo;

byte signalBar[8] = {B11111, B11111, B11111, B11111, B11111, B11111, B11111, B11111};

float angle = 90.0; 
int step = 2; 
int distance;
unsigned long lastManualTime = 0;
unsigned long lastBuzzerTime = 0;
const int joyCenter = 512;

void setup() {
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(buzzerPin, OUTPUT);
  myservo.attach(11);
  
  Serial.begin(9600); // REQUIRED FOR PROCESSING

  lcd.init();
  lcd.backlight();
  lcd.createChar(0, signalBar);
  
  lcd.setCursor(3, 0);
  lcd.print("SENTRY ON");
  tone(buzzerPin, 1500, 100); delay(150);
  tone(buzzerPin, 2000, 100);
  delay(1500);
  lcd.clear();
}

void loop() {
  distance = calculateDistance();
  int joyVal = analogRead(joyX);
  unsigned long currentTime = millis();
  String systemStatus = "SCAN";

  if (abs(joyVal - joyCenter) > 50) {
    float move = (joyVal - joyCenter) / 512.0 * 5.0;
    angle += move;
    lastManualTime = currentTime;
    systemStatus = "MANU";
  } 
  else if (distance > 0 && distance < lockThreshold) {
    if (distance < dangerThreshold) systemStatus = "FIRE";
    else systemStatus = "LOCK";
    angle += (sin(currentTime / 150.0) * 4); 
  }
  else if (currentTime - lastManualTime < 2000) {
    systemStatus = "MANU";
  }
  else {
    systemStatus = "SCAN";
    angle += step * 2.5;
    if (angle >= 170 || angle <= 10) step = -step;
  }

  handleBuzzer(distance);
  updateVisualLCD(systemStatus, distance);

  angle = constrain(angle, 10, 170);
  myservo.write((int)angle);

  // --- SEND DATA TO PROCESSING ---
  // Format: angle,distance,status.
  Serial.print((int)angle);
  Serial.print(",");
  Serial.print(distance);
  Serial.print(",");
  Serial.print(systemStatus);
  Serial.print("."); 
  
  delay(20); 
}

void handleBuzzer(int dist) {
  unsigned long now = millis();
  if (dist > 0 && dist < dangerThreshold) {
    tone(buzzerPin, (now % 300 < 150) ? 2500 : 1800, 40);
  } 
  else if (dist > 0 && dist < lockThreshold) {
    int interval = map(dist, dangerThreshold, lockThreshold, 70, 500);
    int pitch = map(dist, dangerThreshold, lockThreshold, 2200, 800);
    if (now - lastBuzzerTime > interval) {
      tone(buzzerPin, pitch, 40);
      lastBuzzerTime = now;
    }
  } else {
    noTone(buzzerPin);
  }
}

void updateVisualLCD(String status, int dist) {
  lcd.setCursor(0, 0);
  lcd.print(status);
  lcd.print(" ");
  lcd.print((int)angle);
  lcd.print((char)223);
  lcd.print("      "); 
  int bars = map(constrain(dist, 0, 100), 0, 100, 5, 0);
  lcd.setCursor(11, 0);
  for (int i = 0; i < 5; i++) {
    if (i < bars) lcd.write(0);
    else lcd.print(".");
  }
  lcd.setCursor(0, 1);
  if (dist < 100) {
    lcd.print("RANGE: ");
    lcd.print(dist);
    lcd.print("cm    ");
  } else {
    lcd.print("SEARCHING...    ");
  }
}

int calculateDistance() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  long dur = pulseIn(echoPin, HIGH, 25000);
  if (dur == 0) return 400;
  return dur * 0.034 / 2;
}