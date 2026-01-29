import SwiftUI

struct DebugTerminalOverlay: View {
    @ObservedObject var logger: DebugLogger
    
    private let dimGreen = Color(red: 0.0, green: 0.8, blue: 0.4)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 80)
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(logger.entries.prefix(30)) { entry in
                            HStack(alignment: .top, spacing: 4) {
                                Text("[\(entry.source)]")
                                    .foregroundColor(dimGreen.opacity(0.5))
                                Text(entry.message)
                                    .foregroundColor(dimGreen.opacity(0.7))
                            }
                            .font(.system(size: 9, design: .monospaced))
                            .id(entry.id)
                        }
                    }
                }
                .onChange(of: logger.entries.count) { _ in
                    if let first = logger.entries.first {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(first.id, anchor: .top)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .allowsHitTesting(false)
    }
}
