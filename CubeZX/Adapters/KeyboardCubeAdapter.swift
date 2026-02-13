import CoreBluetooth
import Foundation

final class KeyboardCubeAdapter: SmartCubeAdapter {
    let id = UUID()
    let displayName = "Keyboard"
    let serviceUUIDs: [CBUUID] = []
    weak var delegate: SmartCubeAdapterDelegate?

    private var isConnected = false

    func matches(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        false
    }

    func activate() {
        // Don't set isConnected = true - keyboard adapter is virtual, not a real connection
        delegate?.adapter(self, didReceiveDebug: "Keyboard adapter activated")
    }

    func attach(peripheral: CBPeripheral, manager: CBCentralManager) {
        isConnected = true
        delegate?.adapter(self, didChangeConnection: true)
        delegate?.adapter(self, didReceiveDebug: "Keyboard adapter activated")
    }

    func detach() {
        isConnected = false
        delegate?.adapter(self, didChangeConnection: false)
    }

    func handle(characteristic: CBCharacteristic) {
    }

    func sendMove(_ move: CubeMove) {
        guard isConnected else {
            print("Keyboard adapter not connected, ignoring move: \(move.notation)")
            return
        }
        print("Keyboard adapter sending move: \(move.notation)")
        delegate?.adapter(self, didReceiveMove: move)
    }
}

struct KeyboardCubeAdapterFactory: SmartCubeAdapterFactory {
    let name = "Keyboard"
    let serviceUUIDs: [CBUUID] = []

    func makeAdapter() -> SmartCubeAdapter {
        KeyboardCubeAdapter()
    }

    func matches(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        false
    }
}
