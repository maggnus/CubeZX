import CoreBluetooth
import Foundation

protocol SmartCubeAdapterDelegate: AnyObject {
    func adapter(_ adapter: SmartCubeAdapter, didUpdateState state: CubeState)
    func adapter(_ adapter: SmartCubeAdapter, didReceiveMove move: CubeMove)
    func adapter(_ adapter: SmartCubeAdapter, didChangeConnection isConnected: Bool)
    func adapter(_ adapter: SmartCubeAdapter, didReceiveDebug message: String)
    func adapter(_ adapter: SmartCubeAdapter, didUpdateBattery level: Int)
    func adapter(_ adapter: SmartCubeAdapter, didReceiveGyro x: Int16, y: Int16, z: Int16)
    func adapter(_ adapter: SmartCubeAdapter, didReceiveQuaternion w: Int16, x: Int16, y: Int16, z: Int16)
    // Called when adapter provides a corrected device orientation as a simd quaternion
    func adapter(_ adapter: SmartCubeAdapter, didReceiveOrientation orientation: simd_quatf)
}

protocol SmartCubeAdapter: AnyObject {
    var id: UUID { get }
    var displayName: String { get }
    var serviceUUIDs: [CBUUID] { get }
    var delegate: SmartCubeAdapterDelegate? { get set }

    func matches(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool
    func attach(peripheral: CBPeripheral, manager: CBCentralManager)
    func detach()
    func handle(characteristic: CBCharacteristic)
    func resync()  // Request fresh state from device
    func resetCubeState()  // Reset cube to solved state
}

extension SmartCubeAdapter {
    func resync() {}  // Default no-op
    func resetCubeState() {}  // Default no-op
}

extension SmartCubeAdapterDelegate {
    func adapter(_ adapter: SmartCubeAdapter, didUpdateBattery level: Int) {}
    func adapter(_ adapter: SmartCubeAdapter, didReceiveGyro x: Int16, y: Int16, z: Int16) {}
    func adapter(_ adapter: SmartCubeAdapter, didReceiveQuaternion w: Int16, x: Int16, y: Int16, z: Int16) {}
    func adapter(_ adapter: SmartCubeAdapter, didReceiveOrientation orientation: simd_quatf) {}
}
