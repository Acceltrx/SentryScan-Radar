import processing.serial.*; 
import java.awt.Toolkit; 

Serial myPort;
String data = "";
String angle = "";
String distance = "";
String status = "SCAN"; // Added to track Arduino status
int iAngle = 0;
int iDistance = 0;
float pixsDistance;

long lastBeepTime = 0; 
int beepInterval = 600; 

color colorMain = color(0, 255, 200);      
color colorObject = color(255, 50, 50);    
color colorBg = color(10, 15, 20);         
color colorGrid = color(0, 255, 200, 50);  

void setup() {
  size(1200, 800); 
  smooth(8);
  println(Serial.list());
  try {
    myPort = new Serial(this, "COM5", 9600); // Ensure COM port matches Arduino
    myPort.bufferUntil('.'); 
  } catch (Exception e) {
    println("Serial Port not found.");
  }
}

void draw() {
  noStroke();
  fill(colorBg, 25); 
  rect(0, 0, width, height); 

  drawBackgroundGrid();
  drawRadar();
  drawSweepLine();
  drawDetectedObject();
  drawUI();
  
  if (iDistance > 0 && iDistance < 40) {
    if (millis() - lastBeepTime > beepInterval) {
      Toolkit.getDefaultToolkit().beep(); 
      lastBeepTime = millis();            
    }
    noFill();
    stroke(255, 0, 0, 100);
    strokeWeight(20);
    rect(0, 0, width, height);
  }
}

void serialEvent(Serial myPort) {
  try {
    data = myPort.readStringUntil('.');
    if (data != null) {
      data = data.substring(0, data.length()-1);
      String[] list = split(data, ',');
      if (list.length >= 3) {
        angle = list[0];
        distance = list[1];
        status = list[2]; // Get status from Arduino
        iAngle = int(angle);
        iDistance = int(distance);
      }
    }
  } catch (Exception e) {}
}

void drawBackgroundGrid() {
  stroke(colorGrid);
  strokeWeight(0.5);
  for (int i = 0; i < width; i += 50) line(i, 0, i, height);
  for (int i = 0; i < height; i += 50) line(0, i, width, i);
}

void drawRadar() {
  pushMatrix();
  translate(width/2, height - 100); 
  noFill();
  strokeWeight(2);
  stroke(colorMain);
  for (int i = 1; i <= 4; i++) {
    float r = (width - 100) * (i * 0.25);
    arc(0, 0, r, r, PI, TWO_PI);
  }
  for (int i = 0; i <= 180; i += 30) {
    float x = (width/2 - 50) * cos(radians(i));
    float y = (width/2 - 50) * sin(radians(i));
    stroke(colorGrid);
    line(0, 0, -x, -y);
  }
  popMatrix();
}

void drawSweepLine() {
  pushMatrix();
  translate(width/2, height - 100);
  strokeWeight(4);
  for (int i = 0; i < 10; i++) {
    // radians(-iAngle) maps 0 to Right, 90 to Top, 180 to Left
    float angleRad = radians(-iAngle); 
    
    // Optional: If you want the "tail" to look better, 
    // you would normally offset angleRad here based on movement.
    // For now, we simply fix the orientation as requested:
    stroke(0, 255, 200, 255 - (i * 25));
    line(0, 0, (width/2 - 50) * cos(angleRad), (width/2 - 50) * sin(angleRad));
  }
  popMatrix();
}

void drawDetectedObject() {
  pushMatrix();
  translate(width/2, height - 100);
  float maxRangePx = (width/2 - 60);
  pixsDistance = (iDistance <= 40) ? (iDistance * maxRangePx / 40) : 0;
  
  if (iDistance > 0 && iDistance < 40) {
    // Match the sweep line orientation: 0 is Right, 180 is Left
    float targetAngle = radians(-iAngle);
    float x = pixsDistance * cos(targetAngle);
    float y = pixsDistance * sin(targetAngle);
    
    fill(255, 0, 0, 150);
    noStroke();
    ellipse(x, y, 25, 25);
    
    stroke(colorObject);
    strokeWeight(5);
    // Draw the red vertical marker line
    line(x, y, (width/2 - 50) * cos(targetAngle), (width/2 - 50) * sin(targetAngle));
  }
  popMatrix();
} 

void drawUI() {
  fill(5, 10, 15);
  noStroke();
  rect(0, height - 80, width, 80);
  stroke(colorMain);
  line(0, height - 80, width, height - 80);
  
  fill(colorMain);
  textSize(18);
  text("10cm", width * 0.62, height - 110);
  text("20cm", width * 0.75, height - 110);
  text("30cm", width * 0.87, height - 110);
  text("40cm", width * 0.96, height - 110);
  
  textSize(35);
  text("RADAR SYSTEM", 50, height - 35);
  
  textSize(22);
  fill(255);
  text("MODE: " + status, width * 0.3, height - 35); // Now shows MANU, SCAN, LOCK, FIRE
  text("ANGLE: " + iAngle + "°", width * 0.5, height - 35);
  
  if (iDistance < 40) {
    fill(colorObject);
    text("DIST: " + iDistance + " cm", width * 0.7, height - 35);
    beepInterval = (iDistance < 15) ? 200 : 600;
  } else {
    fill(colorMain, 150);
    text("SCANNING...", width * 0.7, height - 35);
  }
  
  if (frameCount % 60 < 30) {
    fill(colorMain);
    if (status.equals("FIRE") || status.equals("LOCK")) fill(255, 0, 0);
    if (status.equals("MANU")) fill(255, 255, 0);
    ellipse(30, height - 45, 10, 10);
  }
}
