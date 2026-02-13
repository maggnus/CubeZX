import SwiftUI

struct ConnectionStatusView: View {
    @ObservedObject var model: CubeAppModel

    var body: some View {
        HStack(spacing: 8) {
            if model.isConnected {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)

                if let name = model.connectedDeviceName {
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.white)
                }

                if let battery = model.batteryLevel {
                    BatteryIndicator(level: battery)
                }

                Button(action: { model.disconnect() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            } else if model.isDiscoveryPresented {
                // Cube is being discovered but not yet connected - hide buttons
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)

                Text("Disconnected")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            } else {
                // Cube is not connected and not being discovered - show "disconnected" text
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)

                Text("Disconnected")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
    }
}

struct BatteryIndicator: View {
    let level: Int
    
    var batteryColor: Color {
        if level > 50 {
            return .green
        } else if level > 20 {
            return .yellow
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: batteryIcon)
                .foregroundColor(batteryColor)
                .font(.caption)
            
            Text("\(level)%")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    var batteryIcon: String {
        if level > 75 {
            return "battery.100"
        } else if level > 50 {
            return "battery.75"
        } else if level > 25 {
            return "battery.50"
        } else if level > 10 {
            return "battery.25"
        } else {
            return "battery.0"
        }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            ConnectionStatusView(model: {
                let m = CubeAppModel()
                m.isConnected = true
                m.connectedDeviceName = "XMD-TornadoV4-i-0A87"
                m.batteryLevel = 85
                return m
            }())
            
            ConnectionStatusView(model: CubeAppModel())
        }
    }
}
