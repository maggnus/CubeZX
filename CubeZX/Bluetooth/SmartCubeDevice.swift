import Foundation

struct SmartCubeDevice: Identifiable, Hashable {
    let id: UUID
    let name: String
    let rssi: Int
    let lastSeen: Date
}
