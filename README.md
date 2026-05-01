# Sentry-Scan: Autonomous Tracking Radar System

An integrated hardware-software solution featuring an autonomous radar system that detects, tracks, and visualizes objects in real-time. This project combines embedded C++ (Arduino) with Java-based visualization (Processing) to create a functional "Sentry Mode" radar.

## 🚀 Features
- **Triple-Mode Operation**: 
  - **SCAN**: Standard 180° autonomous sweep.
  - **LOCK/FIRE**: Object detection triggers a "Hunting" mode, where the servo performs a sinusoidal micro-sweep to track object movement.
  - **MANU**: Manual override via joystick/potentiometer for user-directed scanning.
- **Dynamic Audio Feedback**: Variable frequency and pitch alerts via a Piezo buzzer that increase in intensity as objects approach.
- **Hardware Telemetry**: A 16x2 I2C LCD provides real-time status, angle coordinates, and a custom-rendered proximity bar graph.
- **Graphical UI**: A custom Processing application provides a desktop-class radar visualization, including distance markers and motion-blurred sweep lines.

---

## 🛠️ Hardware Components (BOM)
Based on the system design, the following components were utilized:

| Component | Description | Reference |
| :--- | :--- | :--- |
| **Arduino Uno R3** | Primary Microcontroller Unit | U1 |
| **Ultrasonic Sensor** | 4-pin (HC-SR04) Distance Measurement | DIST1 |
| **Micro Servo** | High-torque Positional Rotation | SERVO1 |
| **16x2 LCD (I2C)** | MCP23008-based Status Display | U2 |
| **Joystick** | Joystick Module | Joystick |
| **Piezo Buzzer** | Acoustic Proximity Alert | PIEZO1 |

---

## 📐 Pin Mapping + Demo
insert image + video demo link

---

## 💻 System Architecture

### Embedded Logic (Arduino)
The firmware is built on a non-blocking state machine. Instead of using `delay()`, the system utilizes `millis()` timing to allow simultaneous servo movement, distance sensing, and audio tone generation.
- **Target Acquisition**: Once an object enters the `lockThreshold` (40cm), the system transitions from a linear sweep to a "Hunting" algorithm using a Sinusoidal function to oscillate the sensor around the target's center of mass.
- **Signal Processing**: Raw ultrasonic data is converted to centimeters and smoothed to prevent jitter in the UI visualization.

### Data Protocol
The Arduino communicates with the Processing UI via a custom Serial data packet sent every 20ms:
`[Angle],[Distance],[Status].` 
*Example: `120,15,LOCK.`*

### Desktop Visualization (Processing)
The Java-based UI interprets the Serial stream to render:
- A semi-circular radar grid.
- A motion-blurred sweep line representing the current sensor orientation.
- Red target indicators with persistence effects.
- A system-level beep synchronized with the hardware alerts.

---

## 📂 Installation & Usage
1. **Arduino**: Upload the `.ino` sketch to your Uno R3. Ensure the `LiquidCrystal_I2C` and `Servo` libraries are installed.
2. **Processing**: Open the `.pde` sketch. Update the `COM` port string to match your Arduino's port (e.g., `"COM5"`).
3. **Operation**: 
   - Leave the joystick idle to begin **Auto-Scan**.
   - Move the joystick to take **Manual Control**.
   - Watch the Desktop UI for high-fidelity object tracking.

---