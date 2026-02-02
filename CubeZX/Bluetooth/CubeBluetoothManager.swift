import CoreBluetooth
import Foundation
import Logging

final class CubeBluetoothManager: NSObject, ObservableObject {
    @Published private(set) var discoveredCubes: [SmartCubeDevice] = []
    @Published private(set) var isScanning = false
    @Published private(set) var bluetoothState: CBManagerState = .unknown

    private let centralManager: CBCentralManager
    private var knownPeripherals: [UUID: CBPeripheral] = [:]
    private var seenDeviceIds: Set<UUID> = []
    private let registry = SmartCubeAdapterRegistry.shared
    private let logger = Logger(label: "com.qwibi.cubezx.CubeBluetoothManager")
    var autoStartScanning = false  // Set by CubeAppModel for background scanning

    override init() {
        self.centralManager = CBCentralManager(delegate: nil, queue: .main)
        super.init()
        self.centralManager.delegate = self
    }

    func startScanning() {
        guard bluetoothState == .poweredOn else {
            logger.info("Waiting for Bluetooth...")
            return
        }
        isScanning = true
        discoveredCubes.removeAll()
        seenDeviceIds.removeAll()
        knownPeripherals.removeAll()  // Clear stale peripheral references
        logger.info("Scanning for smart cubes...")
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
        logger.info("Scan stopped")
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
            logger.info("Bluetooth ready")
            // Auto-start scanning if enabled
            if autoStartScanning && !isScanning {
                startScanning()
            }
        } else {
            logger.info("Bluetooth state: \(central.state.rawValue)")
            stopScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let deviceId = peripheral.identifier
        let isFirstSeen = !seenDeviceIds.contains(deviceId)
        
        if isFirstSeen {
            seenDeviceIds.insert(deviceId)
            let name = peripheral.name ?? "Unknown"
            logger.info("Found: \(name)")
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
                self.logger.info(Logger.Message(stringLiteral: "Smart cube: \(name) (\(adapterName))"))
                self.discoveredCubes.append(device)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Connected to \(peripheral.name ?? "unknown")")
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("Disconnected from \(peripheral.name ?? "unknown"): \(error?.localizedDescription ?? "no error")")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.warning("Failed to connect: \(error?.localizedDescription ?? "unknown")")
    }
}
