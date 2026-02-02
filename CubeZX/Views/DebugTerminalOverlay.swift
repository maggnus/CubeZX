import SwiftUI

struct DebugTerminalOverlay: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 80)
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        // Empty view since we removed the log storage
                        Text("Logging disabled")
                            .foregroundColor(Color.green.opacity(0.7))
                            .font(.system(size: 9, design: .monospaced))
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .allowsHitTesting(false)
    }
}
