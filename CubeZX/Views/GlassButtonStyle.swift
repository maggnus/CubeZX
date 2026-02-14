//
//  GlassButtonStyle.swift
//  CubeSync
//
//  Custom button styles for glassmorphic UI
//

import SwiftUI

// MARK: - Button Styles

/// Primary action button with gradient background
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Gradient background
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.neonCyan,
                                    Color.electricBlue
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Shine effect
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(
                color: Color.neonCyan.opacity(0.3),
                radius: configuration.isPressed ? 5 : 10,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Glass-style button with frosted effect
struct GlassButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundColor(isSelected ? .neonCyan : .white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                    
                    // Selection highlight
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.neonCyan.opacity(0.15))
                    }
                    
                    // Border
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? 
                                Color.neonCyan.opacity(0.5) : 
                                Color.white.opacity(0.15),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                }
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Icon-only circular button
struct IconButtonStyle: ButtonStyle {
    let size: CGFloat
    let backgroundOpacity: Double
    
    init(size: CGFloat = 44, backgroundOpacity: Double = 0.1) {
        self.size = size
        self.backgroundOpacity = backgroundOpacity
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.4))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Timer control button (large touch target)
struct TimerButtonStyle: ButtonStyle {
    let isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.largeTitle.weight(.bold))
            .foregroundColor(isActive ? .solarOrange : .white)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                ZStack {
                    if isActive {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.solarOrange.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    }
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isActive ? Color.solarOrange.opacity(0.5) : Color.white.opacity(0.1),
                            lineWidth: isActive ? 2 : 1
                        )
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Convenience View Modifiers

extension View {
    func primaryButton() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    func glassButton(isSelected: Bool = false) -> some View {
        self.buttonStyle(GlassButtonStyle(isSelected: isSelected))
    }
    
    func iconButton(size: CGFloat = 44) -> some View {
        self.buttonStyle(IconButtonStyle(size: size))
    }
}

// MARK: - Convenience Buttons

struct GlassButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    init(icon: String, label: String, action: @escaping () -> Void = {}) {
        self.icon = icon
        self.label = label
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
        }
        .glassButton()
    }
}

struct PrimaryButton: View {
    let icon: String?
    let label: String
    let action: () -> Void
    
    init(icon: String? = nil, label: String, action: @escaping () -> Void = {}) {
        self.icon = icon
        self.label = label
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(label)
            }
        }
        .primaryButton()
    }
}

// MARK: - Previews

#Preview("Button Styles") {
    ZStack {
        // Background
        LinearGradient(
            colors: [
                Color(hex: "#0A0A0F"),
                Color(hex: "#1E1E2E")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 30) {
                // Primary buttons
                VStack(spacing: 16) {
                    Text("Primary Buttons")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button("Start Solving") {}
                        .primaryButton()
                    
                    PrimaryButton(icon: "stopwatch", label: "Start Timer")
                    
                    PrimaryButton(icon: "arrow.right", label: "Continue") {}
                        .disabled(true)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Glass buttons
                VStack(spacing: 16) {
                    Text("Glass Buttons")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Button("Reset") {}
                            .glassButton()
                        
                        Button("Sync") {}
                            .glassButton(isSelected: true)
                        
                        Button("Scramble") {}
                            .glassButton()
                    }
                    
                    HStack(spacing: 20) {
                        GlassButton(icon: "arrow.counterclockwise", label: "Reset")
                        GlassButton(icon: "arrow.triangle.2.circlepath", label: "Sync")
                        GlassButton(icon: "shuffle", label: "Scramble")
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Icon buttons
                VStack(spacing: 16) {
                    Text("Icon Buttons")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "gearshape")
                        }
                        .iconButton()
                        
                        Button(action: {}) {
                            Image(systemName: "bell")
                        }
                        .iconButton()
                        
                        Button(action: {}) {
                            Image(systemName: "person")
                        }
                        .iconButton(size: 50)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Timer buttons
                VStack(spacing: 16) {
                    Text("Timer Controls")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button("HOLD TO START") {}
                        .buttonStyle(TimerButtonStyle(isActive: false))
                    
                    Button("SOLVING...") {}
                        .buttonStyle(TimerButtonStyle(isActive: true))
                }
            }
            .padding()
        }
    }
}
