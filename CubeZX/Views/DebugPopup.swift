import SwiftUI

struct DebugPopup: View {
    @ObservedObject var logger: DebugLogger
    let cubeOrientation: String
    let onClose: () -> Void
    
    private let hackerGreen = Color(red: 0.0, green: 1.0, blue: 0.3)
    private let dimGreen = Color(red: 0.0, green: 0.6, blue: 0.2)
    
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("[ CUBE_DEBUG_CONSOLE ]")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(hackerGreen)
                Spacer()
                Text(cubeOrientation)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(dimGreen)
                Spacer()
                Button(action: onClose) {
                    Text("[X]")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(hackerGreen)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)
            
            Rectangle()
                .fill(hackerGreen.opacity(0.3))
                .frame(height: 1)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(logger.entries) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text(timeFormatter.string(from: entry.timestamp))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(dimGreen.opacity(0.7))
                                Text("[\(entry.source)]")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(dimGreen)
                                Text(entry.message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(hackerGreen)
                            }
                            .id(entry.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: logger.entries.count) { _ in
                    if let first = logger.entries.first {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(first.id, anchor: .top)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.95))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(hackerGreen.opacity(0.5), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
}
