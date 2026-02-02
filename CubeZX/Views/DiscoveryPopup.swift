import SwiftUI

struct DiscoveryPopup: View {
    @ObservedObject var model: CubeAppModel
    @ObservedObject var bluetoothManager: CubeBluetoothManager
    @State private var scanningRotation: Double = 0
    
    init(model: CubeAppModel) {
        self.model = model
        self.bluetoothManager = model.bluetoothManager
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "cube.transparent")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Discover Cubes (\(bluetoothManager.discoveredCubes.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { model.stopDiscovery() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))

            if bluetoothManager.discoveredCubes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(scanningRotation))
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                scanningRotation = 360
                            }
                        }
                    
                    Text("Scanning for nearby cubes...")
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Make sure your cube is turned on")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(bluetoothManager.discoveredCubes) { device in
                            DeviceRow(device: device) {
                                model.connect(to: device)
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }

        }
        .padding(20)
        .onAppear {
            bluetoothManager.startScanning()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .frame(maxWidth: 400, maxHeight: 500)
        .padding(40)
    }
}

struct DeviceRow: View {
    let device: SmartCubeDevice
    let onConnect: () -> Void
    
    var signalStrength: Int {
        let rssi = device.rssi
        if rssi > -50 { return 4 }
        if rssi > -60 { return 3 }
        if rssi > -70 { return 2 }
        return 1
    }
    
    var body: some View {
        Button(action: onConnect) {
            HStack(spacing: 12) {
                Image(systemName: "cube.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(deviceType)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                SignalStrengthIndicator(strength: signalStrength)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    var deviceType: String {
        if device.name.lowercased().contains("tornado") {
            return "QiYi Tornado V4"
        }
        return "Smart Cube"
    }
}

struct SignalStrengthIndicator: View {
    let strength: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...4, id: \.self) { bar in
                RoundedRectangle(cornerRadius: 1)
                    .fill(bar <= strength ? Color.green : Color.white.opacity(0.2))
                    .frame(width: 3, height: CGFloat(bar * 3 + 4))
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        DiscoveryPopup(model: CubeAppModel())
    }
}
