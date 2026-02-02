import CoreBluetooth
import Foundation

protocol SmartCubeAdapterFactory {
    var name: String { get }
    var serviceUUIDs: [CBUUID] { get }
    func makeAdapter() -> SmartCubeAdapter
    func matches(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool
}

final class SmartCubeAdapterRegistry {
    static let shared = SmartCubeAdapterRegistry()

    private var factories: [SmartCubeAdapterFactory] = []

    func register(factory: SmartCubeAdapterFactory) {
        factories.append(factory)
    }
    
    func isSupported(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        factories.contains { $0.matches(peripheral: peripheral, advertisementData: advertisementData) }
    }
    
    func adapterName(for peripheral: CBPeripheral, advertisementData: [String: Any]) -> String? {
        factories.first { $0.matches(peripheral: peripheral, advertisementData: advertisementData) }?.name
    }

    func adapter(for peripheral: CBPeripheral, advertisementData: [String: Any]) -> SmartCubeAdapter? {
        factories.first { factory in
            factory.matches(peripheral: peripheral, advertisementData: advertisementData)
        }?.makeAdapter()
    }

    func knownServiceUUIDs() -> [CBUUID] {
        factories.flatMap { $0.serviceUUIDs }
    }
}
