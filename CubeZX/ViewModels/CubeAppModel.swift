import CoreBluetooth
import Foundation

final class CubeAppModel: ObservableObject {
    @Published var cubeState: CubeState = .solved()
    @Published var isDiscoveryPresented = false
    @Published var isDebugPresented = true
    @Published var isNotationPresented = false
    @Published var pendingMove: CubeMove?
    @Published var shouldReset = false
    @Published var cubeOrientationString = "ROT: x=0.00 y=0.00 z=0.00"
    
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var connectedDeviceName: String?
    @Published var batteryLevel: Int?
    
    @Published var isDebugModeEnabled = true
    @Published var showRawBLEData = false
    @Published var showDebugOverlay = true
    
    private(set) var faceMapping = CubeFaceMapping()

    let bluetoothManager = CubeBluetoothManager()
    let debugLogger = DebugLogger()

    private var activeAdapter: SmartCubeAdapter?
    private(set) var keyboardAdapter: KeyboardCubeAdapter

    init() {
        keyboardAdapter = KeyboardCubeAdapter()
        bluetoothManager.debugLogger = debugLogger
        debugLogger.log("CubeAppModel initialized", source: "System")
        debugLogger.log("BT state on init: \(bluetoothManager.bluetoothState.rawValue)", source: "BLE")
        registerDefaultAdapters()
        activateKeyboardAdapter()
    }

    private func activateKeyboardAdapter() {
        keyboardAdapter.delegate = self
        activeAdapter = keyboardAdapter
        debugLogger.log("Keyboard adapter ready", source: "System")
    }

    func startDiscovery() {
        bluetoothManager.startScanning()
        isDiscoveryPresented = true
        debugLogger.log("Started scanning for cubes.", source: "Bluetooth")
    }

    func stopDiscovery() {
        bluetoothManager.stopScanning()
        isDiscoveryPresented = false
        debugLogger.log("Stopped scanning for cubes.", source: "Bluetooth")
    }

    func connect(to device: SmartCubeDevice) {
        guard let peripheral = bluetoothManager.peripheral(for: device) else { return }
        let registry = SmartCubeAdapterRegistry.shared
        let adapter = registry.adapter(for: peripheral, advertisementData: [:])
        activeAdapter = adapter
        adapter?.delegate = self
        connectedDeviceName = device.name
        if let adapter {
            adapter.attach(peripheral: peripheral, manager: bluetoothManager.manager())
            stopDiscovery()
        } else {
            debugLogger.log("No adapter matched for device \(device.name)", source: "Bluetooth")
        }
        debugLogger.log("Connecting to \(device.name)", source: "Bluetooth")
    }
    
    func disconnect() {
        activeAdapter?.detach()
        activeAdapter = nil
        isConnected = false
        connectedDeviceName = nil
        batteryLevel = nil
        activateKeyboardAdapter()
        debugLogger.log("Disconnected from cube", source: "Bluetooth")
    }

    func apply(move: CubeMove) {
        pendingMove = move
        debugLogger.log("Move: \(move.notation)", source: "Input")
    }

    func onMoveAnimated() {
        if let move = pendingMove {
            cubeState.apply(move)
            pendingMove = nil
        }
    }

    func resetCube() {
        cubeState = .solved()
        shouldReset = true
        faceMapping = CubeFaceMapping()
        debugLogger.log("Cube reset to solved state", source: "System")
    }

    func onResetComplete() {
        shouldReset = false
        cubeOrientationString = "ROT: x=0.00 y=0.00 z=0.00"
    }
    
    func applyRotation(_ rotation: CubeRotation, direction: CubeMoveDirection) {
        faceMapping.applyRotation(rotation, direction: direction)
        debugLogger.log("Orientation: \(faceMapping.description)", source: "System")
    }

    func updateOrientation(x: Float, y: Float, z: Float, w: Float) {
        let msg = String(format: "x=%.2f y=%.2f z=%.2f w=%.2f", x, y, z, w)
        debugLogger.log(msg, source: "Orientation")
    }

    private func registerDefaultAdapters() {
        SmartCubeAdapterRegistry.shared.register(factory: KeyboardCubeAdapterFactory())
        SmartCubeAdapterRegistry.shared.register(factory: TornadoV4AdapterFactory())
    }
}

extension CubeAppModel: SmartCubeAdapterDelegate {
    func adapter(_ adapter: SmartCubeAdapter, didUpdateState state: CubeState) {
        cubeState = state
        debugLogger.log("State updated from adapter", source: adapter.displayName)
    }

    func adapter(_ adapter: SmartCubeAdapter, didReceiveMove move: CubeMove) {
        apply(move: move)
    }

    func adapter(_ adapter: SmartCubeAdapter, didChangeConnection connected: Bool) {
        isConnected = connected
        if !connected {
            connectedDeviceName = nil
            batteryLevel = nil
        }
        debugLogger.log(connected ? "Connected" : "Disconnected", source: adapter.displayName)
    }

    func adapter(_ adapter: SmartCubeAdapter, didReceiveDebug message: String) {
        guard isDebugModeEnabled else { return }
        
        if !showRawBLEData && (message.hasPrefix("RX:") || message.hasPrefix("DEC:")) {
            return
        }
        
        debugLogger.log(message, source: adapter.displayName)
    }
    
    func adapter(_ adapter: SmartCubeAdapter, didUpdateBattery level: Int) {
        batteryLevel = level
        debugLogger.log("Battery: \(level)%", source: adapter.displayName)
    }
}
