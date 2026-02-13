import Combine
import CoreBluetooth
import Foundation
import Logging
import simd

final class CubeAppModel: ObservableObject {
    @Published var cubeState: CubeState = .solved()
    @Published var isDiscoveryPresented = false
    @Published var isDebugPresented = false
    @Published var isNotationPresented = false
    @Published var pendingMove: CubeMove?  // Current move being animated (even if instant)
    private var moveQueue: [CubeMove] = []  // Queue of moves waiting to be animated (even if instant)
    @Published var shouldReset = false
    @Published var shouldSyncState = false  // Triggers 3D view to sync from cubeState

    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var connectedDeviceName: String?
    @Published var deviceMAC: String?  // MAC address extracted from device name
    @Published var batteryLevel: Int?
    @Published var moveCount: Int = 0  // Total moves since connection

    // For auto-reconnect
    private var lastConnectedMAC: String?
    private var cancellables = Set<AnyCancellable>()
    @Published var disableAutoConnect = false  // Flag to disable auto-connect when user manually disconnects

    @Published var isDebugModeEnabled = true
    @Published var showRawBLEData = false
    @Published var showDebugOverlay = true
    @Published var showGyroDebug = false
    @Published var showDecodedPayload = false {  // Show decoded message payload
        didSet {
            activeAdapter?.showDecodedPayload = showDecodedPayload
        }
    }

    // Default orientation: simplest logical baseline (no rotation).
    // Use identity quaternion so the app starts from a neutral orientation
    // and any visual adjustments are pure rotations applied later.
    private static let defaultOrientation: simd_quatf = simd_quatf(
        angle: 0, axis: simd_float3(0, 1, 0))

    // Quaternion orientation from sensor (with user offset applied)
    // Will be initialized to defaultOrientation in init()
    @Published var quatW: Float = 1.0
    @Published var quatX: Float = 0.0
    @Published var quatY: Float = 0.0
    @Published var quatZ: Float = 0.0

    // Raw sensor quaternion (before offset)
    private var rawSensorQuat: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    // User offset quaternion (applied to sensor data) - start with default orientation
    private var userOffset: simd_quatf = defaultOrientation

    // Track if user is currently dragging
    private var isUserDragging = false

    // Auto-calibration: calibrate orientation after gyro data stabilizes
    private var hasAutoCalibrated = false
    private var autoCalibrationTimer: Timer?

    func onUserInteraction() {
        isUserDragging = true
    }

    // Called continuously during drag - update offset to match user's view
    func updateUserOffset(viewQuatX: Float, viewQuatY: Float, viewQuatZ: Float, viewQuatW: Float) {
        let userOrientation = simd_quatf(ix: viewQuatX, iy: viewQuatY, iz: viewQuatZ, r: viewQuatW)
        // offset = userOrientation * inverse(rawSensor)
        userOffset = userOrientation * rawSensorQuat.inverse
        // Also update published values to match
        quatW = viewQuatW
        quatX = viewQuatX
        quatY = viewQuatY
        quatZ = viewQuatZ
    }

    // Called when drag ends
    func onDragEnded() {
        isUserDragging = false
    }

    // Inlined X-axis 90° rotations were previously available as helper methods.
    // The transformations are now applied directly where needed.

    // Reset orientation offset so cube appears at default orientation (white up, red front)
    func resetOrientationOffset() {
        // Set offset so that offset * rawSensor = defaultOrientation
        userOffset = Self.defaultOrientation * rawSensorQuat.inverse
        applyCurrentOrientation()
    }

    // Creates default face mapping with standard orientation
    private static func makeDefaultFaceMapping() -> CubeFaceMapping {
        // Standard orientation: U=white, D=yellow, F=green, B=blue, L=orange, R=red
        // No rotation compensation needed with standard orientation
        return CubeFaceMapping()
    }

    // Face mapping - standard orientation
    private(set) var faceMapping: CubeFaceMapping = makeDefaultFaceMapping()

    let bluetoothManager = CubeBluetoothManager()
    private let logger = Logger(label: "com.qwibi.cubezx.CubeAppModel")

    private var activeAdapter: SmartCubeAdapter?
    private(set) var keyboardAdapter: KeyboardCubeAdapter

    // Flag to track if we're in the middle of a state sync to prevent adding moves to queue during sync
    private var isSyncingState = false

    init() {
        keyboardAdapter = KeyboardCubeAdapter()
        // Initialize orientation to default
        quatW = Self.defaultOrientation.real
        quatX = Self.defaultOrientation.imag.x
        quatY = Self.defaultOrientation.imag.y
        quatZ = Self.defaultOrientation.imag.z

        bluetoothManager.autoStartScanning = true  // Enable background scanning
        logger.info("CubeAppModel initialized")
        logger.info("BT state on init: \(bluetoothManager.bluetoothState.rawValue)")

        registerDefaultAdapters()
        activateKeyboardAdapter()
        setupAutoScan()
        // Apply default red/orange X-axis counter-clockwise 90° rotation so
        // the view starts with that orientation by default.
        let xAngle = Float.pi / 2
        let xRotation = simd_quatf(angle: xAngle, axis: simd_float3(1, 0, 0))
        userOffset = xRotation * userOffset
        applyCurrentOrientation()
        // (Z-axis rotation removed)
    }

    private func setupAutoScan() {
        // Watch for discovered cubes
        bluetoothManager.$discoveredCubes
            .sink { [weak self] cubes in
                guard let self = self, !self.isConnected, !self.isConnecting else { return }

                for cube in cubes {
                    // Extract MAC from device name
                    if let range = cube.name.range(of: "-", options: .backwards) {
                        let mac = String(cube.name[range.upperBound...])

                    // Auto-connect if matches last connected device and auto-connect is not disabled
                    if let lastMAC = self.lastConnectedMAC, mac == lastMAC, !disableAutoConnect {
                        self.logger.info("Auto-reconnecting to \(cube.name)")
                        self.connect(to: cube)
                        return
                    }
                    }
                }

                // Show discovery popup if cubes found and not auto-connecting
                if !cubes.isEmpty && !self.isDiscoveryPresented {
                    self.isDiscoveryPresented = true
                }
            }
            .store(in: &cancellables)
    }

    private func startBackgroundScanning() {
        guard !isConnected else { return }
        bluetoothManager.startScanning()
        logger.info("Background scanning started")
    }

    private func activateKeyboardAdapter() {
        keyboardAdapter.delegate = self
        activeAdapter = keyboardAdapter
        keyboardAdapter.activate()
        logger.info("Keyboard adapter ready")
    }

    func startDiscovery() {
        bluetoothManager.startScanning()
        isDiscoveryPresented = true
        logger.info("Started scanning for cubes")
    }

    func stopDiscovery() {
        bluetoothManager.stopScanning()
        isDiscoveryPresented = false
        logger.info("Stopped scanning for cubes")
    }

    func connect(to device: SmartCubeDevice) {
        guard let peripheral = bluetoothManager.peripheral(for: device) else { return }
        isConnecting = true
        let registry = SmartCubeAdapterRegistry.shared
        let adapter = registry.adapter(for: peripheral, advertisementData: [:])
        activeAdapter = adapter
        adapter?.delegate = self
        connectedDeviceName = device.name
        // Extract MAC from device name (e.g., "XMD-Tornado-V4-i-0A87" → "0A87")
        if let range = device.name.range(of: "-", options: .backwards) {
            let mac = String(device.name[range.upperBound...])
            deviceMAC = mac
            lastConnectedMAC = mac  // Remember for auto-reconnect
        }
        moveCount = 0  // Reset move counter on new connection
        if let adapter {
            // Pass debug settings to adapter
            adapter.showDecodedPayload = showDecodedPayload
            bluetoothManager.stopScanning()  // Stop scanning during connection
            adapter.attach(peripheral: peripheral, manager: bluetoothManager.manager())
            isDiscoveryPresented = false
        } else {
            isConnecting = false
            logger.warning("No adapter matched for device \(device.name)")
        }
        logger.info("Connecting to \(device.name)")

    }

    func disconnect() {
        activeAdapter?.detach()
        activeAdapter = nil
        isConnected = false
        connectedDeviceName = nil
        batteryLevel = nil
        disableAutoConnect = true  // Disable auto-connect when user manually disconnects
        activateKeyboardAdapter()
        logger.info("Disconnected from cube")
    }

    func apply(move: CubeMove) {
        // Skip moves during state sync to prevent stale moves from being applied
        if isSyncingState {
            logger.info("Move skipped during sync", metadata: ["move": .string(move.notation)])
            return
        }

        logger.info("Move: \(move.notation)")

        // ALWAYS apply state immediately - this ensures virtual cube stays in sync
        cubeState.apply(move)
        logCubeState("after applying move \(move.notation)")

        // Queue move for animation (visual only, state already updated)
        moveQueue.append(move)

        // Trigger animation if not already animating
        if pendingMove == nil && !moveQueue.isEmpty {
            pendingMove = moveQueue.removeFirst()
        }
    }

    func onMoveAnimated() {
        // Animation completed - state was already applied in apply()
        // Just clear pendingMove and start next animation if queued
        pendingMove = nil

        // Start next animation if queue not empty
        if !moveQueue.isEmpty {
            pendingMove = moveQueue.removeFirst()
        }
    }

    private func logCubeState(_ context: String = "") {
        if isDebugModeEnabled {
            // Log in binary format similar to device sync format only
            logCubeStateBinary(context)
        }
    }

    private func logCubeStateBinary(_ context: String = "") {
        if isDebugModeEnabled {
            // Map CubeColor to protocol nibble values: 0=O, 1=R, 2=Y, 3=W, 4=G, 5=B
            let colorToNibble: [CubeColor: UInt8] = [
                .orange: 0, .red: 1, .yellow: 2, .white: 3, .green: 4, .blue: 5,
            ]

            // Protocol face order: U(0)=W, R(1)=R, F(2)=G, D(3)=Y, L(4)=O, B(5)=B
            // So we need to reorder our facelets to match protocol order
            let protocolOrder: [Int] = [0, 3, 4, 1, 2, 5]  // Our face indices: U->0, R->3, F->4, D->1, L->2, B->5
            var reorderedFacelets: [CubeColor] = Array(repeating: .white, count: 54)

            for (protoFaceIdx, ourFaceIdx) in protocolOrder.enumerated() {
                for i in 0..<9 {
                    let protoIdx = protoFaceIdx * 9 + i
                    let ourIdx = ourFaceIdx * 9 + i
                    reorderedFacelets[protoIdx] = cubeState.facelets[ourIdx]
                }
            }

            // Convert to nibbles and pack into 27 bytes
            var faceletData: [UInt8] = []
            for i in stride(from: 0, to: 54, by: 2) {
                let highNibble = colorToNibble[reorderedFacelets[i]] ?? 0
                let lowNibble = (i + 1 < 54) ? (colorToNibble[reorderedFacelets[i + 1]] ?? 0) : 0
                let byte = (highNibble << 4) | lowNibble
                faceletData.append(byte)
            }

            let hexStr = faceletData.map { String(format: "%02X", $0) }.joined(separator: " ")
            logger.info("Cube data: \(hexStr)", metadata: ["context": .string(context)])
        }
    }

    func resetCube() {
        isSyncingState = true  // Prevent new moves from being added during reset
        cubeState = .solved()
        shouldReset = true
        pendingMove = nil
        moveQueue.removeAll()  // Clear any pending moves
        faceMapping = Self.makeDefaultFaceMapping()
        resetOrientationOffset()  // Reset gyro offset so cube stays at default orientation
        // Reset sync flag immediately since there are no animations to wait for
        isSyncingState = false
        logger.info("Cube reset to solved state")
        logCubeState("after reset to solved")
    }

    /// Request state resync from physical cube
    func resyncCube() {
        activeAdapter?.resync()
    }

    func onResetComplete() {
        shouldReset = false
    }

    func applyRotation(_ rotation: CubeRotation, direction: CubeMoveDirection) {
        // Skip rotations during state sync to prevent interference
        if isSyncingState {
            logger.info(
                "Rotation skipped during sync", metadata: ["rotation": .string("\(rotation)")])
            return
        }
        faceMapping.applyRotation(rotation, direction: direction)
        logger.info("Orientation updated", metadata: ["mapping": .string(faceMapping.description)])
    }

    private func registerDefaultAdapters() {
        SmartCubeAdapterRegistry.shared.register(factory: KeyboardCubeAdapterFactory())
        SmartCubeAdapterRegistry.shared.register(factory: TornadoV4AdapterFactory())
    }
}

extension CubeAppModel: SmartCubeAdapterDelegate {
    func adapter(_ adapter: SmartCubeAdapter, didUpdateState state: CubeState) {
        isSyncingState = true  // Prevent new moves from being added during sync
        cubeState = state
        pendingMove = nil  // Clear any pending move
        moveQueue.removeAll()  // Clear move queue to prevent applying stale moves after sync
        shouldSyncState = true  // Trigger 3D view to sync
        // Reset sync flag immediately since there are no animations to wait for
        isSyncingState = false
        logger.info("State synced from device", metadata: ["adapter": .string(adapter.displayName)])
        logCubeState("after sync from device")
    }

    func onStateSyncComplete() {
        shouldSyncState = false
    }

    func adapter(_ adapter: SmartCubeAdapter, didReceiveMove move: CubeMove) {
        moveCount += 1
        apply(move: move)
    }

    func adapter(_ adapter: SmartCubeAdapter, didChangeConnection connected: Bool) {
        isConnected = connected
        isConnecting = false
        if connected {
            logger.info("Connected", metadata: ["adapter": .string(adapter.displayName)])
        } else {
            connectedDeviceName = nil
            deviceMAC = nil
            batteryLevel = nil
            moveCount = 0
            // Reset auto-calibration for next connection
            hasAutoCalibrated = false
            autoCalibrationTimer?.invalidate()
            autoCalibrationTimer = nil
            // Properly clean up adapter on disconnect (restores BLE delegate for scanning)
            adapter.detach()
            activeAdapter = nil
            activateKeyboardAdapter()
            logger.info(
                "Disconnected, resuming scan", metadata: ["adapter": .string(adapter.displayName)])
            // Restart scanning after disconnect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.startBackgroundScanning()
            }
        }
    }

    func adapter(_ adapter: SmartCubeAdapter, didReceiveDebug message: String) {
        guard isDebugModeEnabled else { return }

        if !showRawBLEData && (message.hasPrefix("RX:") || message.hasPrefix("DEC:")) {
            return
        }

        logger.info(
            Logger.Message(stringLiteral: message),
            metadata: ["source": .string(adapter.displayName)])
    }

    func adapter(_ adapter: SmartCubeAdapter, didUpdateBattery level: Int) {
        batteryLevel = level
        logger.info("Battery: \(level)%", metadata: ["adapter": .string(adapter.displayName)])
    }

    func adapter(_ adapter: SmartCubeAdapter, didReceiveGyro x: Int16, y: Int16, z: Int16) {
        // Legacy gyro handler - not used for Tornado V4
    }

    func adapter(
        _ adapter: SmartCubeAdapter, didReceiveQuaternion w: Int16, x: Int16, y: Int16, z: Int16
    ) {
        // Raw quaternion callback kept for backwards compatibility.
        // Prefer receiving corrected orientation via `didReceiveOrientation`.
    }

    func adapter(_ adapter: SmartCubeAdapter, didReceiveOrientation orientation: simd_quatf) {
        // Adapter provides device-specific mapped/corrected orientation
        rawSensorQuat = orientation
        if showGyroDebug {
            let msg = String(
                format: "Orient quat: w=%.3f x=%.3f y=%.3f z=%.3f", orientation.real,
                orientation.imag.x, orientation.imag.y, orientation.imag.z)
            logger.info(
                Logger.Message(stringLiteral: msg), metadata: ["component": .string("Sensor")])
        }
        if !isUserDragging {
            applyCurrentOrientation()
        }
    }

    private func applyCurrentOrientation() {
        // Apply user offset to get final orientation
        let finalQuat = userOffset * rawSensorQuat
        quatW = finalQuat.real
        quatX = finalQuat.imag.x
        quatY = finalQuat.imag.y
        quatZ = finalQuat.imag.z

        if showGyroDebug {
            let msg = String(
                format: "Quat: w=%.3f x=%.3f y=%.3f z=%.3f", quatW, quatX, quatY, quatZ)
            logger.info(
                Logger.Message(stringLiteral: msg), metadata: ["component": .string("Sensor")])
        }
    }

}
