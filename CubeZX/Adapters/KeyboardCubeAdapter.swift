import CoreBluetooth
import Foundation

final class KeyboardCubeAdapter: SmartCubeAdapter {
    let id = UUID()
    let displayName = "Keyboard"
    let serviceUUIDs: [CBUUID] = []
    weak var delegate: SmartCubeAdapterDelegate?

    func matches(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        false
    }

    func attach(peripheral: CBPeripheral, manager: CBCentralManager) {
        delegate?.adapter(self, didChangeConnection: true)
        delegate?.adapter(self, didReceiveDebug: "Keyboard adapter activated")
    }

    func detach() {
        delegate?.adapter(self, didChangeConnection: false)
    }

    func handle(characteristic: CBCharacteristic) {
    }

    func sendMove(_ move: CubeMove) {
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
