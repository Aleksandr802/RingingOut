//
//  BluetoothManager.swift
//  Ringing Out
//
//  Created by Oleksandr Seminov on 6/29/25.
//

import SwiftUI
import CoreBluetooth
import AVFoundation
import AudioToolbox
import UserNotifications

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate, UNUserNotificationCenterDelegate {
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var audioPlayer: AVAudioPlayer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var isScanning = false
    private var scanTimer: Timer?
    
    // BLE Service and Characteristic UUIDs
    private let SERVICE_UUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let CHARACTERISTIC_UUID_RX = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    private let CHARACTERISTIC_UUID_TX = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

    @Published var isConnected = false
    @Published var statusText = "Not connected"
    @Published var isBeeping = false

    private var txCharacteristic: CBCharacteristic?
    private var rxCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: true,
            CBCentralManagerOptionRestoreIdentifierKey: "RingingOutRestoreKey"
        ])
        setupNotificationCategory()
        UNUserNotificationCenter.current().delegate = self
    }

    func setupNotificationCategory() {
        // Create a custom category for our notifications
        let category = UNNotificationCategory(
            identifier: "TEST_CATEGORY",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction, .hiddenPreviewsShowTitle]
        )
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional, .criticalAlert]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            
            // Configure notification settings for background delivery
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound, .badge, .list])
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in peripherals {
                if peripheral.name == "ESP32_WROOM_BLE_Ringout" {
                    connectedPeripheral = peripheral
                    connectedPeripheral?.delegate = self
                    centralManager?.connect(connectedPeripheral!, options: nil)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == CHARACTERISTIC_UUID_TX,
           let value = characteristic.value,
           let stringValue = String(data: value, encoding: .utf8) {
            
            // Start background task
            startBackgroundTask()
            
            if stringValue == "T" {
                DispatchQueue.main.async {
                    self.startBeeping()
                }
            } else if stringValue == "S" {
                DispatchQueue.main.async {
                    self.stopBeeping()
                }
            }
            
            // End background task
            endBackgroundTask()
        }
    }

    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    func showNotification(title: String, body: String) {
        print("Attempting to show notification: \(title) - \(body)")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.defaultCritical
        content.badge = 1
        content.categoryIdentifier = "TEST_CATEGORY"
        content.threadIdentifier = "TEST_THREAD"
        content.interruptionLevel = .critical // Use critical interruption level
        content.relevanceScore = 1.0
        content.targetContentIdentifier = "RingingOutAlert"
        
        // Create a request with trigger for delivery
        let request = UNNotificationRequest(
            identifier: "RingingOutNotification",
            content: content,
            trigger: nil
        )
        
        // Remove any pending notifications first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Play a system sound to ensure user attention
        AudioServicesPlaySystemSound(1007)
        
        // Ensure notification is delivered even in background
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to show notification: \(error.localizedDescription)")
                } else {
                    print("Successfully queued notification")
                    
                    // Reset badge count after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        UNUserNotificationCenter.current().setBadgeCount(0) { error in
                            if let error = error {
                                print("Failed to reset badge count: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }

    func startScanning() {
        guard let centralManager = centralManager, centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on")
            return
        }
        
        if !isScanning {
            isScanning = true
            statusText = "Scanning..."
            
            // Start scanning with service UUID
            centralManager.scanForPeripherals(withServices: [SERVICE_UUID], options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true
            ])
            
            // Set up scan timer to restart scanning if needed
            scanTimer?.invalidate()
            scanTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if !self.isConnected {
                    print("Restarting scan...")
                    self.centralManager?.stopScan()
                    self.centralManager?.scanForPeripherals(withServices: [self.SERVICE_UUID], options: [
                        CBCentralManagerScanOptionAllowDuplicatesKey: true
                    ])
                }
            }
        }
    }

    func stopScanning() {
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
        centralManager?.stopScan()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            startScanning()
        case .poweredOff:
            print("Bluetooth is powered off")
            stopScanning()
            isConnected = false
            statusText = "Bluetooth is off"
        case .unauthorized:
            print("Bluetooth is unauthorized")
            statusText = "Bluetooth access denied"
        case .unsupported:
            print("Bluetooth is unsupported")
            statusText = "Bluetooth not supported"
        default:
            print("Bluetooth state: \(central.state)")
            statusText = "Bluetooth not available"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        print("Discovered peripheral: \(peripheral.name ?? "Unknown")")
        
        if peripheral.name == "ESP32_WROOM_BLE_Ringout" {
            print("Found target device")
            central.stopScan()
            connectedPeripheral = peripheral
            connectedPeripheral?.delegate = self
            central.connect(connectedPeripheral!, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral")
        isConnected = true
        statusText = "Connected"
        stopScanning()
        showNotification(title: "Bluetooth", body: "Connected to device")
        peripheral.discoverServices([SERVICE_UUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        statusText = "Failed to Connect"
        startScanning() // Restart scanning after failed connection
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral")
        isConnected = false
        statusText = "Disconnected"
        
        // Show disconnect notification with critical priority
        let content = UNMutableNotificationContent()
        content.title = "Bluetooth"
        content.body = "Device disconnected"
        content.sound = UNNotificationSound.defaultCritical
        content.badge = 1
        content.categoryIdentifier = "TEST_CATEGORY"
        content.threadIdentifier = "TEST_THREAD"
        content.interruptionLevel = .critical
        content.relevanceScore = 1.0
        content.targetContentIdentifier = "RingingOutAlert"
        
        let request = UNNotificationRequest(
            identifier: "DisconnectNotification",
            content: content,
            trigger: nil
        )
        
        // Remove any pending notifications first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Play a system sound
        AudioServicesPlaySystemSound(1007)
        
        // Ensure notification is delivered
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to show disconnect notification: \(error.localizedDescription)")
                } else {
                    print("Successfully queued disconnect notification")
                    
                    // Reset badge count after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        UNUserNotificationCenter.current().setBadgeCount(0) { error in
                            if let error = error {
                                print("Failed to reset badge count: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
        
        startScanning() // Restart scanning after disconnection
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == SERVICE_UUID {
                peripheral.discoverCharacteristics([CHARACTERISTIC_UUID_RX, CHARACTERISTIC_UUID_TX], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == CHARACTERISTIC_UUID_TX {
                txCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == CHARACTERISTIC_UUID_RX {
                rxCharacteristic = characteristic
            }
        }
    }

    func startBeeping() {
        if !isBeeping {
            isBeeping = true
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            playBeepSound()
            showNotification(title: "Alert", body: "Cable found!")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.stopBeeping()
            }
        }
    }

    func stopBeeping() {
        if isBeeping {
            isBeeping = false
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            audioPlayer?.stop()
        }
    }

    func playBeepSound() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }

        if let soundURL = Bundle.main.url(forResource: "beep", withExtension: "mp3", subdirectory: "Sounds") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("Error playing beep sound: \(error)")
            }
        } else {
            print("Could not find beep.mp3 in Sounds directory")
        }
    }

    func testBeep() {
        print("Test beep triggered")
        if let rxCharacteristic = rxCharacteristic {
            let data = "T".data(using: .utf8)!
            connectedPeripheral?.writeValue(data, for: rxCharacteristic, type: .withResponse)
            
            // Stop after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                let stopData = "S".data(using: .utf8)!
                self.connectedPeripheral?.writeValue(stopData, for: rxCharacteristic, type: .withResponse)
            }
        }
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        playBeepSound()
        
        // Request notification permission again to ensure it's granted
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    self.showNotification(title: "Test", body: "Testing notification system")
                }
            } else {
                print("Notification permission not granted")
            }
        }
    }
}
