//
//  ContentView.swift
//  Ringing Out
//
//  Created by Oleksandr Seminov on 5/10/25.
//

import SwiftUI
import CoreBluetooth
import AVFoundation
import AudioToolbox
import UserNotifications

struct ContentView: View {
    @ObservedObject var bluetoothManager = BluetoothManager()
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main content with striped border
            ZStack {
                // Background container
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(hex: "2d2d2d"))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                
                // Content
                VStack(spacing: 25) {
                    // Status indicator
                    StatusIndicator(isConnected: bluetoothManager.isConnected)
                        .frame(height: 120)
                    
                    // Status text
                    VStack(spacing: 8) {
                        Text(bluetoothManager.statusText)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(bluetoothManager.isBeeping ? .red : .white)
                            .animation(.easeInOut, value: bluetoothManager.isBeeping)
                        
                        Text(bluetoothManager.isConnected ? "Connected to Ringing Out" : "Searching for device...")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(bluetoothManager.isConnected ? .green : .gray)
                    }
                    .padding(.vertical)
                    
                    // Test button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isAnimating = true
                            bluetoothManager.testBeep()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isAnimating = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20))
                            Text("Test Ringing Out")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "007AFF"), Color(hex: "0055FF")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color(hex: "007AFF").opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .scaleEffect(isAnimating ? 0.95 : 1.0)
                    .disabled(!bluetoothManager.isConnected)
                    .opacity(bluetoothManager.isConnected ? 1.0 : 0.6)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                
                // Striped border
                StripedBorder()
                    .clipShape(RoundedRectangle(cornerRadius: 30))
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            bluetoothManager.startScanning()
            bluetoothManager.requestNotificationPermission()
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("Failed to reset badge count: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
