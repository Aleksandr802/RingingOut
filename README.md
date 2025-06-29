# 🔔 RingingOut: ESP32 BLE Alert System for iOS

RingingOut is a SwiftUI-based iOS app that connects to an ESP32 device over BLE to receive real-time alerts and trigger audible notifications. Ideal for use cases such as smart cable testers, BLE proximity alerts, or location-aware sensors.

## 🚀 Features

- 📱 SwiftUI Interface with gradient animations
- 📶 BLE connection to `ESP32_WROOM_BLE_Ringout`
- 🔄 Auto reconnect and background scanning
- 🔔 Audio + haptic alerts (vibration, critical sound, beeps)
- 🛎 Critical notifications even in background or silent mode
- 🔐 Background task management for reliability
- 🌈 Clean UI with status indicators and test function
- 📬 Local notification handling and custom categories

## 📷 Screenshots

> _Add your screenshots here to showcase the UI and notification alerts._

## 🧰 Technologies Used

- SwiftUI
- CoreBluetooth
- AVFoundation
- AudioToolbox
- UserNotifications
- UIKit (background task and badge handling)

## 📡 Bluetooth Device Requirements

This app is designed to work with ESP32 devices using the **Nordic UART Service (NUS)** UUIDs

Expected BLE message behavior:
- Send `"T"` from ESP32 to start beeping and show alert
- Send `"S"` to stop beeping

## 📲 How to Use

1. Make sure your ESP32 device is advertising with the correct service/characteristics.
2. Launch the app on your iOS device.
3. The app will scan and automatically connect to the `ESP32_WROOM_BLE_Ringout`.
4. Receive alerts and play beeps when triggered from ESP32.
5. Tap **Test Ringing Out** to manually test sound/vibration/notification.

## ⚙️ Permissions Required

- **Bluetooth** access
- **Notifications** (Critical alerts, badges, sound, banners)
- **Background Mode**: BLE communication and notifications

Make sure to enable all permissions when prompted.

