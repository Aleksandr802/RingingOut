//
//  StatusIndicator.swift
//  Ringing Out
//
//  Created by Oleksandr Seminov on 6/29/25.
//

import SwiftUI

// Status indicator view
struct StatusIndicator: View {
    let isConnected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            isConnected ? Color.green.opacity(0.3) : Color.red.opacity(0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .scaleEffect(isConnected ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isConnected)
            
            Circle()
                .stroke(
                    isConnected ? Color.green : Color.red,
                    lineWidth: 4
                )
                .frame(width: 80, height: 80)
            
            Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(isConnected ? .green : .red)
        }
    }
}
