import CoreBluetooth
import Foundation

final class TornadoV4Adapter: NSObject, SmartCubeAdapter {
    let id = UUID()
    let displayName = "Tornado V4 AI"
    let serviceUUIDs: [CBUUID] = [CBUUID(string: "FFF0")]
    weak var delegate: SmartCubeAdapterDelegate?
    
    private static let serviceUUID = CBUUID(string: "FFF0")
    private static let characteristicUUID = CBUUID(string: "FFF6")
    private static let aesKey: [UInt8] = [0x57, 0xB1, 0xF9, 0xAB, 0xCD, 0x5A, 0xE8, 0xA7,
                                           0x9C, 0xB9, 0x8C, 0xE7, 0x57, 0x8C, 0x51, 0x08]
    
    private let crypto = AESCrypto(key: aesKey)
    
    private var peripheral: CBPeripheral?
    private var centralManager: CBCentralManager?
    private var originalManagerDelegate: CBCentralManagerDelegate?  // Store original delegate
    private var dataCharacteristic: CBCharacteristic?
    private var lastMoveSeq: UInt8 = 0xFF  // Shared between EE and DD
    private var isConnected = false
    private var hasSentHandshakeAck = false
    

    
    func matches(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        let name = peripheral.name?.lowercased() ?? ""
        return name.contains("tornado")
    }
    
    func attach(peripheral: CBPeripheral, manager: CBCentralManager) {
        delegate?.adapter(self, didReceiveDebug: "Attaching to \(peripheral.name ?? "unknown")")
        delegate?.adapter(self, didReceiveDebug: "Peripheral state: \(peripheral.state.rawValue)")
        self.peripheral = peripheral
        self.centralManager = manager
        peripheral.delegate = self
        // Store original delegate before overwriting
        originalManagerDelegate = manager.delegate
        manager.delegate = self
        delegate?.adapter(self, didReceiveDebug: "Calling manager.connect()...")
        manager.connect(peripheral, options: nil)
        delegate?.adapter(self, didReceiveDebug: "Connect called, waiting for callback...")
    }
    
    func detach() {
        let wasConnected = isConnected
        if let peripheral = peripheral, let manager = centralManager {
            manager.cancelPeripheralConnection(peripheral)
            // Restore original delegate so scanning works again
            if let original = originalManagerDelegate {
                manager.delegate = original
            }
        }
        peripheral = nil
        centralManager = nil
        originalManagerDelegate = nil
        dataCharacteristic = nil
        isConnected = false
        hasSentHandshakeAck = false
        // Only notify if we were actually connected (prevents double notification)
        if wasConnected {
            delegate?.adapter(self, didChangeConnection: false)
        }
    }
    
    /// Request fresh state from cube (re-sends handshake)
    func resync() {
        guard isConnected else { return }
        hasSentHandshakeAck = false  // Allow sending ACK again
        lastMoveSeq = 0xFF  // Reset seq tracking
        sendHandshake()
        delegate?.adapter(self, didReceiveDebug: "Resync requested")
    }
    
    /// Reset cube's internal state to solved
    /// Sends FE 26 command with solved state facelets (same opcode as handshake response!)
    func resetCubeState() {
        guard isConnected,
              let peripheral = peripheral,
              let characteristic = dataCharacteristic else {
            delegate?.adapter(self, didReceiveDebug: "Reset failed: not connected")
            return
        }
        
        // FE 26 command with solved state - discovered from official app capture
        // Format: FE 26 <flags> <session> <facelets...>
        // Solved facelets: URFDLB order, each nibble is face color (0=L,1=R,2=D,3=U,4=F,5=B)
        // Verified from BLE capture: 33 33 33 33 13 11 11 11 11 44 44 44 44 24 22 22 22 22 00 00 00 00 50 55 55 55 55
        var cmd: [UInt8] = [
            0xFE, 0x26,                         // Header: same as handshake response!
            0x04,                               // Command flag (from capture)
            0xB3, 0x4D, 0x05, 0x0F,             // Session/timestamp (may vary)
            // Solved state facelets (27 bytes for 54 facelets):
            // Protocol face order: URFDLB (Up, Right, Front, Down, Left, Back)
            0x33, 0x33, 0x33, 0x33,             // U face (9 facelets = 4.5 bytes, all 3s)
            0x13,                               // U[8]=3, R[0]=1
            0x11, 0x11, 0x11, 0x11,             // R face (all 1s)
            0x44, 0x44, 0x44, 0x44,             // F face (all 4s)
            0x24,                               // F[8]=4, D[0]=2
            0x22, 0x22, 0x22, 0x22,             // D face (all 2s)
            0x00, 0x00, 0x00, 0x00,             // L face (all 0s)
            0x50,                               // L[8]=0, B[0]=5
            0x55, 0x55, 0x55, 0x55,             // B face (all 5s)
        ]
        
        // Pad to 32 bytes minimum
        while cmd.count < 32 {
            cmd.append(0x00)
        }
        
        // Encrypt and send
        if let encrypted = crypto.encrypt(Data(cmd)) {
            peripheral.writeValue(encrypted, for: characteristic, type: .withoutResponse)
            delegate?.adapter(self, didReceiveDebug: "Sent Reset command (FE 26 with solved state)")
            
            // Reset sequence tracking - cube resets counter to 0 after Reset
            lastMoveSeq = 0xFF
            lastDDSeq = 0xFF
            
            // Update local state to solved
            let solvedState = CubeState.solved()
            delegate?.adapter(self, didUpdateState: solvedState)
        }
    }
    
    func handle(characteristic: CBCharacteristic) {
        guard characteristic.uuid == Self.characteristicUUID,
              let data = characteristic.value,
              data.count >= 16 else { return }
        
        processEncryptedData(data)
    }
    
    private func processEncryptedData(_ data: Data) {
        let hexStr = data.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " ")
        delegate?.adapter(self, didReceiveDebug: "RX: \(hexStr)")
        
        guard let decrypted = crypto.decrypt(data) else {
            delegate?.adapter(self, didReceiveDebug: "Decryption failed")
            return
        }
        
        let prefix = decrypted[0]
        
        // Show decoded payload if enabled (for EE/DD messages)
        if showDecodedPayload && (prefix == 0xEE || prefix == 0xDD) {
            let decHex = decrypted.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " ")
            delegate?.adapter(self, didReceiveDebug: "DEC: \(decHex)")
        }
        
        switch prefix {
        case 0xFE:
            handleHandshakeMessage(decrypted)
        case 0xEE:
            handleMoveMessage(decrypted, msgType: "EE")
        case 0xDD:
            handleDDMessage(decrypted)
        case 0xCC:
            handleGyroMessage(decrypted)
        default:
            delegate?.adapter(self, didReceiveDebug: "Unknown message type: 0x\(String(format: "%02X", prefix))")
        }
    }
    
    private func handleHandshakeMessage(_ data: Data) {
        guard data.count >= 16 else { return }
        
        let opcode = data[1]
        delegate?.adapter(self, didReceiveDebug: "Handshake: opcode=0x\(String(format: "%02X", opcode))")
        
        if opcode == 0x26 {
            delegate?.adapter(self, didReceiveDebug: "Handshake complete, cube ready")
            sendHandshakeAckIfNeeded(from: data)
            
            // Parse cube state from bytes 7-33 (27 bytes = 54 facelets)
            if data.count >= 34 {
                let cubeState = parseFaceletState(from: data)
                delegate?.adapter(self, didUpdateState: cubeState)
                delegate?.adapter(self, didReceiveDebug: "Synced cube state from device")
            }
        }
    }
    
    /// Parse 27 bytes of facelet data into CubeState
    /// Protocol format: each byte contains 2 facelets (4 bits each)
    /// Nibble values 0-5 map to faces: L, R, D, U, F, B
    private func parseFaceletState(from data: Data) -> CubeState {
        // Extract 27 bytes starting at offset 7
        let faceletData = data.subdata(in: 7..<34)
        let ourFacelets = Self.decodeFaceletBytes(faceletData)
        let hexStr = faceletData.map { String(format: "%02X", $0) }.joined(separator: " ")
        delegate?.adapter(self, didReceiveDebug: "Cube data: \(hexStr)")
        let centers = (0..<6).map { idx in ourFacelets[idx * 9 + 4].rawValue }
        delegate?.adapter(self, didReceiveDebug: "Decoded centers: \(centers.joined(separator: ", "))")
        let upFace = ourFacelets[0..<9].map { $0.rawValue }.joined(separator: ",")
        delegate?.adapter(self, didReceiveDebug: "Decoded Up face: \(upFace)")
        return CubeState(facelets: ourFacelets)
    }

    /// Decode 27 bytes of facelet payload into our internal 54-facelet array.
    /// This is exposed as an internal helper so unit tests can verify decoding.
    static func decodeFaceletBytes(_ faceletData: Data) -> [CubeColor] {
        // Protocol nibble values from documentation:
        // 0=Orange, 1=Red, 2=Yellow, 3=White, 4=Green, 5=Blue
        let protocolNibbleToColor: [CubeColor] = [
            .orange,  // 0 → Orange
            .red,     // 1 → Red
            .yellow,  // 2 → Yellow
            .white,   // 3 → White
            .green,   // 4 → Green
            .blue     // 5 → Blue
        ]

        // Parse 54 facelets from 27 bytes using low-nibble-for-even-indices packing
        var protocolFacelets: [Int] = []
        protocolFacelets.reserveCapacity(54)
        for i in 0..<54 {
            let byteIndex = i / 2
            let nibbleShift = (i % 2) * 4 // low nibble for even indices
            let nibble = Int((faceletData[byteIndex] >> nibbleShift) & 0x0F)
            protocolFacelets.append(nibble)
        }

        // Remap protocol face order URFDLB -> internal UDLRFB
        let protocolFaceToOurIndex: [Int] = [0, 3, 4, 1, 2, 5]

        // Per-face inner-index mapping (0..8) to account for orientation differences
        // Initialize with empty inner arrays; specific face mappings set below.
        var faceInnerIndexMap: [[Int]] = Array(repeating: [Int](), count: 6)
        // Up (white): 3x3 inner-index mapping
        faceInnerIndexMap[0] = [6, 7, 8, 3, 4, 5, 0, 1, 2]
        // Down (yellow): 3x3 inner-index mapping
        faceInnerIndexMap[1] = [6, 7, 8, 3, 4, 5, 0, 1, 2]
        // Left (orange): user-requested mapping (keeps intended orientation)
        faceInnerIndexMap[2] = [2, 1, 0, 5, 4, 3, 8, 7, 6]
        // Right (red): user-requested mapping (keeps intended orientation)
        faceInnerIndexMap[3] = [2, 1, 0, 5, 4, 3, 8, 7, 6]
        // Front (green): identity mapping (0..8)
        faceInnerIndexMap[4] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
        // Back (blue): identity mapping (0..8)
        faceInnerIndexMap[5] = [0, 1, 2, 3, 4, 5, 6, 7, 8]

        var ourFacelets: [CubeColor] = Array(repeating: .white, count: 54)
        for protoFace in 0..<6 {
            let ourFace = protocolFaceToOurIndex[protoFace]
            for i in 0..<9 {
                let protoIdx = protoFace * 9 + i
                let mappedInner = faceInnerIndexMap[ourFace][i]
                let ourIdx = ourFace * 9 + mappedInner
                let colorNibble = protocolFacelets[protoIdx]
                if colorNibble >= 0 && colorNibble < protocolNibbleToColor.count {
                    ourFacelets[ourIdx] = protocolNibbleToColor[colorNibble]
                } else {
                    ourFacelets[ourIdx] = .white
                }
            }
        }

        return ourFacelets
    }
    
    private func sendHandshakeAckIfNeeded(from data: Data) {
        guard !hasSentHandshakeAck,
              data.count >= 7,
              let peripheral = peripheral,
              let characteristic = dataCharacteristic else { return }
        
        hasSentHandshakeAck = true
        
        var ack: [UInt8] = [0xFE, 0x09]
        ack.append(contentsOf: data[2...6])
        
        let crc = CRC16.modbus(ack)
        ack.append(UInt8(crc & 0xFF))
        ack.append(UInt8((crc >> 8) & 0xFF))
        
        while ack.count < 16 {
            ack.append(0x00)
        }
        
        if let encrypted = crypto.encrypt(Data(ack)) {
            peripheral.writeValue(encrypted, for: characteristic, type: .withoutResponse)
            delegate?.adapter(self, didReceiveDebug: "Sent handshake ACK")
        }
    }
    
    private var lastDDSeq: UInt8 = 0xFF
    var showDecodedPayload = false  // Set from CubeAppModel
    
    private func handleDDMessage(_ data: Data) {
        guard data.count >= 14 else { return }
        
        let seq = data[2]
        
        // Check if this is a duplicate DD (same seq as last DD)
        let isDuplicate = (seq == lastDDSeq)
        
        if isDuplicate {
            // Second DD with same seq = cube SOLVED!
            delegate?.adapter(self, didReceiveDebug: "DD seq=\(seq) SOLVED")
            lastDDSeq = seq
            
            // Don't resync here - this was causing issues with state comparison
            // The solved state detection is just informational
            return
        }
        
        lastDDSeq = seq
        
        // First DD - process moves normally
        handleMoveMessage(data, msgType: "DD")
    }
    
    private func handleMoveMessage(_ data: Data, msgType: String) {
        guard data.count >= 14 else { return }
        
        let seq = data[2]
        
        // Extract all 3 move slots (slot 0 = newest, slot 2 = oldest)
        let slots: [UInt8] = [
            data[3] >> 4,                              // slot 0 - newest (seq)
            data.count > 7 ? data[7] >> 4 : 0,         // slot 1 - (seq-1)
            data.count > 11 ? data[11] >> 4 : 0       // slot 2 - oldest (seq-2)
        ]
        
        delegate?.adapter(self, didReceiveDebug: "\(msgType) seq=\(seq) slots: [0x\(String(format: "%X", slots[0])), 0x\(String(format: "%X", slots[1])), 0x\(String(format: "%X", slots[2]))]")
        
        // Calculate how many new moves we have
        var seqDiff: Int
        if lastMoveSeq == 0xFF {
            seqDiff = 1  // First message, process only slot 0
        } else {
            // Seq appears to be 0-99 (wraps at 100), not 0-255
            // So 99 → 0 means seqDiff = 1
            let diff = Int(seq) - Int(lastMoveSeq)
            if diff > 50 {
                // Old message (seq jumped backwards a lot)
                seqDiff = diff - 100
            } else if diff < -50 {
                // Wraparound: 99 → 0 gives diff = -99, seqDiff should be 1
                seqDiff = 100 + diff
            } else {
                seqDiff = diff
            }
            
            // Clamp to valid range
            if seqDiff <= 0 {
                // Duplicate or old message
                delegate?.adapter(self, didReceiveDebug: "\(msgType) seq=\(seq) (old/duplicate, skipped)")
                return
            }
            if seqDiff > 3 { seqDiff = 3 }     // Max 3 slots available
        }
        
        lastMoveSeq = seq
        
        // Process moves from oldest to newest (reverse order of slots)
        // Each slot corresponds to a specific seq: slot[i] = seq - i
        for i in stride(from: seqDiff - 1, through: 0, by: -1) {
            let moveByte = slots[i]
            if moveByte != 0 {
                // Calculate the seq for this specific move
                let moveSeq = UInt8((Int(seq) - i + 256) % 256)
                emitFaceMove(moveByte, seq: moveSeq)
            }
        }
    }
    
    private func emitFaceMove(_ byte: UInt8, seq: UInt8) {
        let moveHex = String(format: "0x%X", byte)
        if let move = decodeMove(byte, seq: seq) {
            delegate?.adapter(self, didReceiveDebug: "Move: \(move.notation) [\(moveHex)]")
            delegate?.adapter(self, didReceiveMove: move)
        } else {
            delegate?.adapter(self, didReceiveDebug: "Move: _ [\(moveHex)]")
        }
    }
    
    
    private func handleGyroMessage(_ data: Data) {
        guard data.count >= 14 else { return }
        
        // CC 10 SEQ TS TS ?? QW QW QX QX QY QY QZ QZ
        // Byte 5: flag/constant (skip)
        // Bytes 6-13: Quaternion (w, x, y, z) as signed 16-bit BIG-ENDIAN
        // Values are scaled by ~1000 (unit quaternion * 1000)
        
        let qw = Int16(bitPattern: (UInt16(data[6]) << 8) | UInt16(data[7]))
        let qx = Int16(bitPattern: (UInt16(data[8]) << 8) | UInt16(data[9]))
        let qy = Int16(bitPattern: (UInt16(data[10]) << 8) | UInt16(data[11]))
        let qz = Int16(bitPattern: (UInt16(data[12]) << 8) | UInt16(data[13]))
        
        delegate?.adapter(self, didReceiveQuaternion: qw, x: qx, y: qy, z: qz)
    }
    
    private func decodeMove(_ byte: UInt8, seq: UInt8) -> CubeMove? {
        let face: CubeMoveFace
        let direction: CubeMoveDirection
        
        switch byte {
        case 0x1:
            face = .left
            direction = .counterClockwise
        case 0x2:
            face = .left
            direction = .clockwise
        case 0x3:
            face = .right
            direction = .counterClockwise
        case 0x4:
            face = .right
            direction = .clockwise
        case 0x5:
            face = .down
            direction = .counterClockwise
        case 0x6:
            face = .down
            direction = .clockwise
        case 0x7:
            face = .up
            direction = .counterClockwise
        case 0x8:
            face = .up
            direction = .clockwise
        case 0x9:
            face = .front
            direction = .counterClockwise
        case 0xA:
            face = .front
            direction = .clockwise
        case 0xB:
            face = .back
            direction = .counterClockwise
        case 0xC:
            face = .back
            direction = .clockwise
        default:
            return nil
        }
        
        return CubeMove(face: face, direction: direction, seq: seq)
    }
    
    private func sendHandshake() {
        guard let peripheral = peripheral,
              let characteristic = dataCharacteristic else { return }
        
        var macBytes: [UInt8] = [0xCC, 0xA6, 0x00, 0x00, 0x00, 0x00]
        if let rawName = peripheral.name {
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            if let range = name.range(of: "-", options: .backwards) {
                let hexPart = String(name[range.upperBound...])
                if hexPart.count == 4,
                   let val = UInt16(hexPart, radix: 16) {
                    macBytes[4] = UInt8((val >> 8) & 0xFF)
                    macBytes[5] = UInt8(val & 0xFF)
                }
            }
        }
        
        var hello: [UInt8] = [
            0xFE, 0x15, 0xF0, 0xAE, 0x02, 0x00, 0x00, 0x24,
            0x01, 0x00, 0x02, 0x27, 0x1E
        ]
        hello.append(contentsOf: macBytes.reversed())
        
        let crc = CRC16.modbus(Array(hello[0..<19]))
        hello.append(UInt8(crc & 0xFF))
        hello.append(UInt8((crc >> 8) & 0xFF))
        
        while hello.count < 32 {
            hello.append(0x00)
        }
        
        if let encrypted = crypto.encrypt(Data(hello)) {
            peripheral.writeValue(encrypted, for: characteristic, type: .withoutResponse)
            delegate?.adapter(self, didReceiveDebug: "Sent handshake")
        }
    }
}

extension TornadoV4Adapter: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            delegate?.adapter(self, didReceiveDebug: "Service discovery error: \(error.localizedDescription)")
            return
        }
        
        let services = peripheral.services ?? []
        delegate?.adapter(self, didReceiveDebug: "Found \(services.count) services")
        for service in services {
            delegate?.adapter(self, didReceiveDebug: "Service: \(service.uuid.uuidString)")
            if service.uuid == Self.serviceUUID {
                delegate?.adapter(self, didReceiveDebug: "Found FFF0, discovering characteristics...")
                peripheral.discoverCharacteristics([Self.characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            delegate?.adapter(self, didReceiveDebug: "Characteristic discovery error: \(error.localizedDescription)")
            return
        }
        
        let chars = service.characteristics ?? []
        delegate?.adapter(self, didReceiveDebug: "Found \(chars.count) characteristics in \(service.uuid.uuidString)")
        for characteristic in chars {
            delegate?.adapter(self, didReceiveDebug: "Char: \(characteristic.uuid.uuidString) props: \(characteristic.properties.rawValue)")
            if characteristic.uuid == Self.characteristicUUID {
                dataCharacteristic = characteristic
                delegate?.adapter(self, didReceiveDebug: "Found FFF6, subscribing to notifications...")
                peripheral.setNotifyValue(true, for: characteristic)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.sendHandshake()
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            delegate?.adapter(self, didReceiveDebug: "Value update error: \(error.localizedDescription)")
            return
        }
        handle(characteristic: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            delegate?.adapter(self, didReceiveDebug: "Notification error: \(error.localizedDescription)")
        } else {
            delegate?.adapter(self, didReceiveDebug: "Notifications enabled for \(characteristic.uuid.uuidString)")
        }
    }
}

extension TornadoV4Adapter: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        delegate?.adapter(self, didChangeConnection: true)
        delegate?.adapter(self, didReceiveDebug: "Connected, discovering services...")
        peripheral.discoverServices([Self.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        // Restore original delegate so scanning works again
        if let original = originalManagerDelegate {
            central.delegate = original
            originalManagerDelegate = nil
        }
        delegate?.adapter(self, didChangeConnection: false)
        delegate?.adapter(self, didReceiveDebug: "Disconnected")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        delegate?.adapter(self, didReceiveDebug: "Failed to connect: \(error?.localizedDescription ?? "unknown")")
    }
}

struct TornadoV4AdapterFactory: SmartCubeAdapterFactory {
    let name = "Tornado V4 AI"
    let serviceUUIDs: [CBUUID] = [CBUUID(string: "FFF0")]
    
    func makeAdapter() -> SmartCubeAdapter {
        TornadoV4Adapter()
    }
    
    func matches(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        let name = peripheral.name?.lowercased() ?? ""
        return name.contains("tornado")
    }
}
