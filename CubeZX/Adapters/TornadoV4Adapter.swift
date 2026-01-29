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
    private var dataCharacteristic: CBCharacteristic?
    private var lastMoveSeq: UInt8 = 0xFF
    private var isConnected = false
    private var handshakeComplete = false
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
        manager.delegate = self
        delegate?.adapter(self, didReceiveDebug: "Calling manager.connect()...")
        manager.connect(peripheral, options: nil)
        delegate?.adapter(self, didReceiveDebug: "Connect called, waiting for callback...")
    }
    
    func detach() {
        if let peripheral = peripheral, let manager = centralManager {
            manager.cancelPeripheralConnection(peripheral)
        }
        peripheral = nil
        dataCharacteristic = nil
        isConnected = false
        handshakeComplete = false
        hasSentHandshakeAck = false
        delegate?.adapter(self, didChangeConnection: false)
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
        
        let decHex = decrypted.map { String(format: "%02X", $0) }.joined(separator: " ")
        delegate?.adapter(self, didReceiveDebug: "DEC: \(decHex)")
        
        let prefix = decrypted[0]
        
        switch prefix {
        case 0xFE:
            handleHandshakeMessage(decrypted)
        case 0xEE:
            handleMoveMessage(decrypted)
        case 0xCC:
            break
        default:
            delegate?.adapter(self, didReceiveDebug: "Unknown message type: 0x\(String(format: "%02X", prefix))")
        }
    }
    
    private func handleHandshakeMessage(_ data: Data) {
        guard data.count >= 16 else { return }
        
        let opcode = data[1]
        delegate?.adapter(self, didReceiveDebug: "Handshake: opcode=0x\(String(format: "%02X", opcode))")
        
        if opcode == 0x26 {
            handshakeComplete = true
            delegate?.adapter(self, didReceiveDebug: "Handshake complete, cube ready")
            sendHandshakeAckIfNeeded(from: data)
        }
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
    
    private func handleMoveMessage(_ data: Data) {
        guard data.count >= 14 else { return }
        
        let seq = data[2]
        
        if seq == lastMoveSeq {
            return
        }
        lastMoveSeq = seq
        
        let moveByte = data[3] >> 4
        
        guard let move = decodeMove(moveByte) else {
            delegate?.adapter(self, didReceiveDebug: "Unknown move byte: 0x\(String(format: "%X", moveByte))")
            return
        }
        
        delegate?.adapter(self, didReceiveDebug: "Move: \(move.notation) (seq=\(seq))")
        delegate?.adapter(self, didReceiveMove: move)
    }
    
    private func handleGyroMessage(_ data: Data) {
    }
    
    private func decodeMove(_ byte: UInt8) -> CubeMove? {
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
            face = .back
            direction = .counterClockwise
        case 0x8:
            face = .back
            direction = .clockwise
        case 0x9:
            face = .front
            direction = .counterClockwise
        case 0xA:
            face = .front
            direction = .clockwise
        case 0xB:
            face = .up
            direction = .counterClockwise
        case 0xC:
            face = .up
            direction = .clockwise
        default:
            return nil
        }
        
        return CubeMove(face: face, direction: direction)
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
        handshakeComplete = false
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
