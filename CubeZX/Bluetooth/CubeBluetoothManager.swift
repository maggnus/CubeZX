import CoreBluetooth
import Foundation

final class CubeBluetoothManager: NSObject, ObservableObject {
    @Published private(set) var discoveredCubes: [SmartCubeDevice] = []
    @Published private(set) var isScanning = false
    @Published private(set) var bluetoothState: CBManagerState = .unknown

    private let centralManager: CBCentralManager
    private var knownPeripherals: [UUID: CBPeripheral] = [:]
    private var seenDeviceIds: Set<UUID> = []
    private let registry = SmartCubeAdapterRegistry.shared
    
    var debugLogger: DebugLogger?

    override init() {
        self.centralManager = CBCentralManager(delegate: nil, queue: .main)
        super.init()
        self.centralManager.delegate = self
    }

    func startScanning() {
        guard bluetoothState == .poweredOn else {
            debugLogger?.log("Waiting for Bluetooth...", source: "BLE")
            return
        }
        isScanning = true
        discoveredCubes.removeAll()
        seenDeviceIds.removeAll()
        debugLogger?.log("Scanning for smart cubes...", source: "BLE")
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
        debugLogger?.log("Scan stopped", source: "BLE")
    }

    func peripheral(for device: SmartCubeDevice) -> CBPeripheral? {
        knownPeripherals[device.id]
    }

    func manager() -> CBCentralManager {
        centralManager
    }
}

extension CubeBluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        if central.state == .poweredOn {
            debugLogger?.log("Bluetooth ready", source: "BLE")
        } else {
            debugLogger?.log("Bluetooth state: \(central.state.rawValue)", source: "BLE")
            stopScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let deviceId = peripheral.identifier
        let isFirstSeen = !seenDeviceIds.contains(deviceId)
        
        if isFirstSeen {
            seenDeviceIds.insert(deviceId)
            let name = peripheral.name ?? "Unknown"
            debugLogger?.log("Found: \(name)", source: "BLE")
        }
        
        guard registry.isSupported(peripheral: peripheral, advertisementData: advertisementData) else {
            return
        }
        
        let name = peripheral.name ?? "Smart Cube"
        knownPeripherals[deviceId] = peripheral
        
        let adapterName = registry.adapterName(for: peripheral, advertisementData: advertisementData) ?? "Unknown"
        let device = SmartCubeDevice(id: deviceId, name: name, rssi: RSSI.intValue, lastSeen: Date())
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let index = self.discoveredCubes.firstIndex(where: { $0.id == deviceId }) {
                self.discoveredCubes[index] = device
            } else {
                self.debugLogger?.log("🎲 Smart cube: \(name) (\(adapterName))", source: "BLE")
                self.discoveredCubes.append(device)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debugLogger?.log("Connected to \(peripheral.name ?? "unknown")", source: "BLE")
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        debugLogger?.log("Disconnected from \(peripheral.name ?? "unknown"): \(error?.localizedDescription ?? "no error")", source: "BLE")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        debugLogger?.log("Failed to connect: \(error?.localizedDescription ?? "unknown")", source: "BLE")
    }
}
