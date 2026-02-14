//
//  ColorExtensions.swift
//  CubeSync
//
//  Color palette and extensions for the CubeSync design system
//

import SwiftUI

// MARK: - Design System Colors

extension Color {
    // MARK: Background Colors
    
    /// Deep void black - primary background
    static let deepVoid = Color(hex: "#0A0A0F")
    
    /// Midnight - card backgrounds, panels
    static let midnight = Color(hex: "#12121A")
    
    /// Slate - elevated surfaces, modals
    static let slate = Color(hex: "#1E1E2E")
    
    /// Graphite - borders, dividers
    static let graphite = Color(hex: "#2A2A3A")
    
    // MARK: Accent Colors
    
    /// Neon cyan - primary actions, highlights
    static let neonCyan = Color(hex: "#00D9FF")
    
    /// Electric blue - secondary accents
    static let electricBlue = Color(hex: "#0080FF")
    
    /// Matrix green - success, connected status
    static let matrixGreen = Color(hex: "#00FF88")
    
    /// Plasma purple - special features, achievements
    static let plasmaPurple = Color(hex: "#B829DD")
    
    /// Solar orange - warnings, timer active
    static let solarOrange = Color(hex: "#FF6B35")
    
    /// Alert red - errors, disconnected
    static let alertRed = Color(hex: "#FF3366")
    
    // MARK: Cube Face Colors (Standard)
    
    static let cubeWhite = Color(hex: "#F5F5F5")
    static let cubeYellow = Color(hex: "#FFD500")
    static let cubeGreen = Color(hex: "#009E60")
    static let cubeBlue = Color(hex: "#0051BA")
    static let cubeOrange = Color(hex: "#FF5800")
    static let cubeRed = Color(hex: "#C41E3A")
    
    // MARK: Text Colors
    
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.4)
    
    // MARK: Glass Effects
    
    static let glassBackground = Color(hex: "#1E1E2E").opacity(0.75)
    static let glassBorder = Color.white.opacity(0.1)
}

// MARK: - Hex Color Initializer

extension Color {
    /// Initialize Color from hex string
    /// Supports: 3-digit (#RGB), 6-digit (#RRGGBB), 8-digit (#AARRGGBB)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RRGGBB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // AARRGGBB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradient Definitions

extension LinearGradient {
    /// Ambient background gradient
    static let ambient = LinearGradient(
        colors: [
            Color.deepVoid,
            Color.midnight,
            Color(hex: "#0D1B2A").opacity(0.4)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Card highlight gradient
    static let cardHighlight = LinearGradient(
        colors: [
            Color.white.opacity(0.1),
            Color.white.opacity(0.02)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Primary action gradient
    static let primaryAction = LinearGradient(
        colors: [.neonCyan, .electricBlue],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Success gradient
    static let success = LinearGradient(
        colors: [.matrixGreen, Color(hex: "#00CC6A")],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension RadialGradient {
    /// Accent glow effect
    static let accentGlow = RadialGradient(
        colors: [
            Color.neonCyan.opacity(0.3),
            Color.clear
        ],
        center: .center,
        startRadius: 0,
        endRadius: 200
    )
}

// MARK: - Semantic Colors

enum SemanticColor {
    case success, warning, error, info
    
    var color: Color {
        switch self {
        case .success: return .matrixGreen
        case .warning: return .solarOrange
        case .error: return .alertRed
        case .info: return .neonCyan
        }
    }
    
    var background: Color {
        color.opacity(0.15)
    }
}

// MARK: - Theme Manager

@Observable
class ThemeManager {
    var accentColor: AccentColor = .cyan
    var backgroundStyle: BackgroundStyle = .gradient
    
    enum AccentColor: String, CaseIterable {
        case cyan = "Cyan"
        case blue = "Blue"
        case green = "Green"
        case purple = "Purple"
        case orange = "Orange"
        
        var color: Color {
            switch self {
            case .cyan: return .neonCyan
            case .blue: return .electricBlue
            case .green: return .matrixGreen
            case .purple: return .plasmaPurple
            case .orange: return .solarOrange
            }
        }
    }
    
    enum BackgroundStyle: String, CaseIterable {
        case gradient = "Gradient"
        case solid = "Solid"
        case particles = "Particles"
        case grid = "Grid"
    }
}

// MARK: - Previews

#Preview("Color Palette") {
    ScrollView(.vertical, showsIndicators: true) {
        VStack(spacing: 20) {
            // Background colors
            Group {
                Text("Background Colors")
                    .font(.headline)
                
                HStack(spacing: 10) {
                    ColorChip(color: .deepVoid, name: "Deep Void")
                    ColorChip(color: .midnight, name: "Midnight")
                    ColorChip(color: .slate, name: "Slate")
                    ColorChip(color: .graphite, name: "Graphite")
                }
            }
            
            Divider()
            
            // Accent colors
            Group {
                Text("Accent Colors")
                    .font(.headline)
                
                HStack(spacing: 10) {
                    ColorChip(color: .neonCyan, name: "Neon Cyan")
                    ColorChip(color: .electricBlue, name: "Electric Blue")
                    ColorChip(color: .matrixGreen, name: "Matrix Green")
                }
                
                HStack(spacing: 10) {
                    ColorChip(color: .plasmaPurple, name: "Plasma Purple")
                    ColorChip(color: .solarOrange, name: "Solar Orange")
                    ColorChip(color: .alertRed, name: "Alert Red")
                }
            }
            
            Divider()
            
            // Cube colors
            Group {
                Text("Cube Face Colors")
                    .font(.headline)
                
                HStack(spacing: 10) {
                    ColorChip(color: .cubeWhite, name: "White")
                    ColorChip(color: .cubeYellow, name: "Yellow")
                    ColorChip(color: .cubeGreen, name: "Green")
                }
                
                HStack(spacing: 10) {
                    ColorChip(color: .cubeBlue, name: "Blue")
                    ColorChip(color: .cubeOrange, name: "Orange")
                    ColorChip(color: .cubeRed, name: "Red")
                }
            }
        }
        .padding()
    }
    .background(Color.deepVoid)
}

struct ColorChip: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 80, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            Text(name)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}
