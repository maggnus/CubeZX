//
//  GlassCardView.swift
//  CubeSync
//
//  Glassmorphic card component for modern UI
//

import SwiftUI

/// A glassmorphic card view with frosted glass effect
struct GlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let backgroundOpacity: Double
    let showBorder: Bool
    
    init(
        cornerRadius: CGFloat = 20,
        backgroundOpacity: Double = 0.15,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.backgroundOpacity = backgroundOpacity
        self.showBorder = showBorder
    }
    
    var body: some View {
        content
            .padding()
            .background(
                ZStack {
                    // Frosted glass background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle gradient overlay for depth
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border
                    if showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
            )
            .shadow(
                color: Color.black.opacity(0.25),
                radius: 15,
                x: 0,
                y: 8
            )
    }
}

/// A smaller glass pill-style badge
struct GlassBadge: View {
    let text: String
    let icon: String?
    let color: Color
    
    init(
        _ text: String,
        icon: String? = nil,
        color: Color = .neonCyan
    ) {
        self.text = text
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundColor(color)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

/// Glass panel for floating overlays
struct GlassPanel<Content: View>: View {
    let content: Content
    let maxWidth: CGFloat?
    let maxHeight: CGFloat?
    
    init(
        maxWidth: CGFloat? = 400,
        maxHeight: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "#12121A").opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(
                color: Color.black.opacity(0.4),
                radius: 30,
                x: 0,
                y: 15
            )
    }
}

// MARK: - Previews

#Preview("Glass Card Variants") {
    ZStack {
        // Background
        LinearGradient(
            colors: [
                Color(hex: "#0A0A0F"),
                Color(hex: "#12121A")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Standard card
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connected")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Tornado V4 - 84% battery")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Card with custom styling
            GlassCard(
                cornerRadius: 16,
                backgroundOpacity: 0.2
            ) {
                HStack {
                    Image(systemName: "stopwatch")
                        .font(.title2)
                        .foregroundColor(.neonCyan)
                    
                    VStack(alignment: .leading) {
                        Text("Session Average")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text("14.52s")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
            }
            
            // Badges
            HStack(spacing: 12) {
                GlassBadge("Connected", icon: "checkmark.circle.fill", color: .matrixGreen)
                GlassBadge("Timer", icon: "stopwatch", color: .solarOrange)
                GlassBadge("12 Solves", color: .neonCyan)
            }
            
            // Glass panel
            GlassPanel {
                VStack(spacing: 16) {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 48))
                        .foregroundColor(.neonCyan)
                    
                    Text("Discovery")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Scanning for nearby cubes...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
    }
}
