//
//  StripedBorder.swift
//  Ringing Out
//
//  Created by Oleksandr Seminov on 6/29/25.
//

import SwiftUICore

struct StripedBorder: View {
    var body: some View {
        GeometryReader { geometry in
            let horizontalStripeWidth: CGFloat = 70
            let horizontalStripeHeight: CGFloat = 8
            let verticalStripeWidth: CGFloat = 8
            let verticalStripeHeight: CGFloat = 70

            ZStack {
                // Top border
                HStack(spacing: 0) {
                    ForEach(0..<Int(geometry.size.width / horizontalStripeWidth), id: \.self) { index in
                        Rectangle()
                            .fill(index.isMultiple(of: 2) ? Color.yellow : Color.black)
                            .frame(width: horizontalStripeWidth, height: horizontalStripeHeight)
                    }
                }
                .position(x: geometry.size.width / 2, y: horizontalStripeHeight / 2)
                
                // Bottom border
                HStack(spacing: 0) {
                    ForEach(0..<Int(geometry.size.width / horizontalStripeWidth), id: \.self) { index in
                        Rectangle()
                            .fill(index.isMultiple(of: 2) ? Color.yellow : Color.black)
                            .frame(width: horizontalStripeWidth, height: horizontalStripeHeight)
                    }
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height - horizontalStripeHeight / 2)
                
                // Left border
                VStack(spacing: 0) {
                    ForEach(0..<Int(geometry.size.height / verticalStripeHeight), id: \.self) { index in
                        Rectangle()
                            .fill(index.isMultiple(of: 2) ? Color.yellow : Color.black)
                            .frame(width: verticalStripeWidth, height: verticalStripeHeight)
                    }
                }
                .position(x: verticalStripeWidth / 2, y: geometry.size.height / 2)
                
                // Right border
                VStack(spacing: 0) {
                    ForEach(0..<Int(geometry.size.height / verticalStripeHeight), id: \.self) { index in
                        Rectangle()
                            .fill(index.isMultiple(of: 2) ? Color.yellow : Color.black)
                            .frame(width: verticalStripeWidth, height: verticalStripeHeight)
                    }
                }
                .position(x: geometry.size.width - verticalStripeWidth / 2, y: geometry.size.height / 2)
            }
        }
    }
}
