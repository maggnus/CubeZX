import CoreBluetooth
import Foundation

protocol SmartCubeAdapterDelegate: AnyObject {
    func adapter(_ adapter: SmartCubeAdapter, didUpdateState state: CubeState)
    func adapter(_ adapter: SmartCubeAdapter, didReceiveMove move: CubeMove)
    func adapter(_ adapter: SmartCubeAdapter, didChangeConnection isConnected: Bool)
    func adapter(_ adapter: SmartCubeAdapter, didReceiveDebug message: String)
    func adapter(_ adapter: SmartCubeAdapter, didUpdateBattery level: Int)
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
}

extension SmartCubeAdapterDelegate {
    func adapter(_ adapter: SmartCubeAdapter, didUpdateBattery level: Int) {}
}
