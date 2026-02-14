//
//  StatusIndicators.swift
//  CubeSync
//
//  Connection status, badges, and animated indicators
//

import SwiftUI

// MARK: - Connection Status Indicator

struct ConnectionStatusIndicator: View {
    let status: ConnectionStatus
    let deviceName: String?
    let batteryLevel: Int?
    
    var body: some View {
        GlassCard(cornerRadius: 16, showBorder: true) {
            HStack(spacing: 12) {
                // Animated status dot
                StatusDot(status: status)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusText)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                    
                    if let name = deviceName, status == .connected {
                        Text(name)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                if let battery = batteryLevel, status == .connected {
                    BatteryIndicator(level: battery)
                }
            }
        }
    }
    
    private var statusText: String {
        switch status {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .scanning:
            return "Scanning..."
        case .error:
            return "Connection Error"
        }
    }
}

// MARK: - Status Dot

struct StatusDot: View {
    let status: ConnectionStatus
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Pulse ring
            if status == .connected || status == .scanning {
                Circle()
                    .fill(status.color)
                    .frame(width: 20, height: 20)
                    .scaleEffect(isPulsing ? 2.0 : 1.0)
                    .opacity(isPulsing ? 0 : 0.4)
            }
            
            // Core dot
            Circle()
                .fill(status.color)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(status.color.opacity(0.5), lineWidth: 1)
                )
        }
        .onAppear {
            if status == .connected || status == .scanning {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
        }
    }
}

// MARK: - Connection Status Badge

struct ConnectionBadge: View {
    let status: ConnectionStatus
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            
            Text(status.label)
                .font(.caption2.weight(.semibold))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(status.color.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(status.color.opacity(0.25), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Loading Spinner

struct CubeSpinner: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.neonCyan, .electricBlue, .plasmaPurple, .neonCyan],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: 50, height: 50)
            
            // Inner cube representation
            Image(systemName: "cube.transparent")
                .font(.title2)
                .foregroundColor(.neonCyan)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.5)],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Connection Status Enum

enum ConnectionStatus: Equatable {
    case connected
    case connecting
    case disconnected
    case scanning
    case error(String)
    
    var color: Color {
        switch self {
        case .connected:
            return .matrixGreen
        case .connecting:
            return .neonCyan
        case .disconnected:
            return .textTertiary
        case .scanning:
            return .electricBlue
        case .error:
            return .alertRed
        }
    }
    
    var label: String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Disconnected"
        case .scanning:
            return "Scanning"
        case .error:
            return "Error"
        }
    }
}

// MARK: - Previews

#Preview("Status Indicators") {
    ZStack {
        Color.deepVoid.ignoresSafeArea()
        
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                // Connection statuses
                Group {
                    Text("Connection Status")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ConnectionStatusIndicator(
                        status: .connected,
                        deviceName: "Tornado V4-A87",
                        batteryLevel: 84
                    )
                    
                    ConnectionStatusIndicator(
                        status: .scanning,
                        deviceName: nil,
                        batteryLevel: nil
                    )
                    
                    ConnectionStatusIndicator(
                        status: .disconnected,
                        deviceName: nil,
                        batteryLevel: nil
                    )
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Badges
                Group {
                    Text("Badges")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        ConnectionBadge(status: .connected)
                        ConnectionBadge(status: .connecting)
                        ConnectionBadge(status: .scanning)
                        ConnectionBadge(status: .error(""))
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Battery levels
                Group {
                    Text("Battery Indicators")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        BatteryIndicator(level: 85)
                        BatteryIndicator(level: 45)
                        BatteryIndicator(level: 15)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Signal strength
                Group {
                    Text("Signal Strength")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        SignalStrengthIndicator(strength: 4)
                        SignalStrengthIndicator(strength: 3)
                        SignalStrengthIndicator(strength: 2)
                        SignalStrengthIndicator(strength: 1)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Loading spinner
                Group {
                    Text("Loading Spinner")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    CubeSpinner()
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Progress ring
                Group {
                    Text("Progress Ring")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ZStack {
                        ProgressRing(progress: 0.75, lineWidth: 8, color: .neonCyan)
                            .frame(width: 80, height: 80)
                        
                        Text("75%")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
    }
}
