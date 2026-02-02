import SwiftUI

struct CubeInfoOverlay: View {
    @ObservedObject var model: CubeAppModel
    
    private let dimCyan = Color(red: 0.4, green: 0.8, blue: 1.0)
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Spacer()
                .frame(height: 80)
            
            VStack(alignment: .trailing, spacing: 2) {
                // Device info
                InfoRow(label: "Device", value: model.connectedDeviceName ?? "—")
                
                if model.isConnected {
                    InfoRow(label: "MAC", value: model.deviceMAC ?? "—")
                    
                    if let battery = model.batteryLevel {
                        InfoRow(label: "Battery", value: "\(battery)%")
                    }
                    
                    Spacer().frame(height: 8)
                    
                    // Orientation in our coordinates
                    InfoRow(label: "Quat", value: String(format: "%.2f %.2f %.2f %.2f", 
                        model.quatW, model.quatX, model.quatY, model.quatZ))
                    
                    Spacer().frame(height: 8)
                    
                    // Move info
                    InfoRow(label: "Move #", value: "\(model.moveCount)")
                    
                    if model.showDecodedPayload {
                        InfoRow(label: "Decode", value: "ON")
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .allowsHitTesting(false)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    private let dimCyan = Color(red: 0.4, green: 0.8, blue: 1.0)
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundColor(dimCyan.opacity(0.5))
            Text(value)
                .foregroundColor(dimCyan.opacity(0.8))
        }
        .font(.system(size: 9, design: .monospaced))
    }
}
