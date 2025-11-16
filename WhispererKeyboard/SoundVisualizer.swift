//
//  SoundVisualizer.swift
//  WhispererKeyboard
//
//  Created on 12/19/24.
//

import SwiftUI

/// Displays a single pulsating mic icon to indicate that audio is being captured.
struct SoundVisualizer: View {
    let powerLevel: Float
    
    private var normalizedLevel: CGFloat {
        let clamped = max(-80, min(0, powerLevel))
        return CGFloat((clamped + 80) / 80)
    }
    
    private var scale: CGFloat {
        1.0 + normalizedLevel * 0.35
    }
    
    private var glowOpacity: Double {
        Double(0.3 + normalizedLevel * 0.7)
    }
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let circleSize = size * (0.95 + normalizedLevel * 0.25)
            let iconSize = size * 0.45
            
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: circleSize, height: circleSize)
                    .shadow(color: .orange.opacity(glowOpacity), radius: 30 * scale)
                    .animation(.easeOut(duration: 0.2), value: circleSize)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: iconSize, weight: .black))
                    .foregroundColor(.orange)
                    .scaleEffect(scale)
                    .shadow(color: .orange.opacity(glowOpacity), radius: 18 * scale)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: scale)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .accessibilityLabel("Recording microphone level")
    }
}

