import SwiftUI

struct DebugPopup: View {
    @ObservedObject var logger: DebugLogger
    let cubeOrientation: String
    @Binding var isDebugEnabled: Bool
    @Binding var showRawData: Bool
    @Binding var showOverlay: Bool
    let onClose: () -> Void
    
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Debug")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(cubeOrientation)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }

            Divider()
                .background(Color.white.opacity(0.2))

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Debug mode", isOn: $isDebugEnabled)
                Toggle("Show raw BLE data", isOn: $showRawData)
                Toggle("Show debug overlay", isOn: $showOverlay)
            }
            .tint(.blue)
            .padding(.vertical, 4)

            Divider()
                .background(Color.white.opacity(0.2))

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .frame(maxWidth: 420, maxHeight: 500)
        .padding(40)
    }
}
