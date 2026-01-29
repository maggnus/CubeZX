import Foundation

struct DebugLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let source: String
}

final class DebugLogger: ObservableObject {
    @Published private(set) var entries: [DebugLogEntry] = []
    
    private let logFileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("cubezx_debug.log")
    }()
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return df
    }()
    
    init() {
        try? FileManager.default.removeItem(at: logFileURL)
        log("Log file: \(logFileURL.path)", source: "System")
    }

    func log(_ message: String, source: String = "System") {
        let timestamp = dateFormatter.string(from: Date())
        let line = "[\(timestamp)] [\(source)] \(message)"
        print(line)
        
        if let data = (line + "\n").data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let handle = try? FileHandle(forWritingTo: logFileURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
        
        let entry = DebugLogEntry(timestamp: Date(), message: message, source: source)
        DispatchQueue.main.async {
            self.entries.insert(entry, at: 0)
        }
    }
}
