# QiYi Tornado V4 Smart Cube Protocol Specification

## Overview

The QiYi Tornado V4 is a Bluetooth-enabled smart Rubik's cube that sends encrypted telemetry data including turn information, battery level, and 3D orientation. This document provides a comprehensive reverse-engineered specification based on extensive analysis of real captured data.

## Table of Contents

- [GATT Profile](#gatt-profile)
- [Encryption](#encryption)
- [Message Structure](#message-structure)
- [Message Types](#message-types)
- [Checksum](#checksum)
- [Known Opcodes](#known-opcodes)
- [Turn Detection](#turn-detection)
- [Orientation Data](#orientation-data)
- [BLE Implementation Challenges](#ble-implementation-challenges)
- [Unknown Areas](#unknown-areas)
- [Implementation Notes](#implementation-notes)

---

## GATT Profile

The protocol uses Bluetooth Low Energy (BLE) with the following GATT profile:

- **Service `1801`**
  - Characteristic `2a05`
- **Service `fff0`**
  - Characteristic `fff4`
  - Characteristic `fff5`
  - Characteristic `fff6` (primary data channel)
  - Characteristic `fff7`
- **Service `5833ff01-9b8b-5191-6142-22a4536ef123`**
  - Characteristic `5833ff02-9b8b-5191-6142-22a4536ef123`
  - Characteristic `5833ff03-9b8b-5191-6142-22a4536ef123`

**Primary communication**: WRITEs and NOTIFYs on characteristic `fff6`

---

## Encryption

All messages are encrypted using AES-128 in ECB mode with a fixed key:

```
AES Key: 57 b1 f9 ab cd 5a e8 a7 9c b9 8c e7 57 8c 51 08
[87, 177, 249, 171, 205, 90, 232, 167, 156, 185, 140, 231, 87, 140, 81, 8]
```

### Encryption Process
1. **Padding**: Messages are padded with trailing zeros to a multiple of 16 bytes
2. **Block Cipher**: Each 16-byte block is encrypted independently
3. **ECB Mode**: No chaining between blocks

### Decryption
```swift
let key = SymmetricKey(data: Data(AES_KEY))
let cipher = AES.ECB(key: key)
let decrypted = cipher.decrypt(block)
```

---

## Message Structure

All messages follow this basic structure:

```
[Header: 1 byte] [Length: 1 byte] [Opcode: 1 byte] [Payload: variable] [CRC16: 2 bytes] [Padding: 0-15 bytes]
```

- **Header**: Always `0xFE`
- **Length**: Payload length (excluding padding)
- **Opcode**: Message type identifier
- **Payload**: Message-specific data
- **CRC16**: MODBUS checksum of header + payload (little-endian)
- **Padding**: Zeros to reach 16-byte boundary

---

## Message Types

| Opcode | Name | Direction | Needs ACK? | Length | Description |
|--------|------|-----------|----------|---------|-------------|
| `0x6B` | Unknown | Unknown | 202 | **CONTAINS ORIENTATION DATA** |
| `0x00` | Unknown | Unknown | 254 | Large data message |
| `0x34` | Unknown | Unknown | 12 | **CONTAINS ORIENTATION DATA** |
| `0x03` | State Change | Conditional | 94 | Turn data + cube state |
| `0x02` | Cube Hello | Yes | 38 | Initial cube state + battery |
| `0x04` | Sync Confirmation | No | 38 | Response to sync command |

---

## Checksum

- **Algorithm**: CRC-16-MODBUS
- **Range**: Header + payload (excluding padding)
- **Byte Order**: Little-endian
- **Polynomial**: `0x8005` (standard MODBUS)

### CRC16 Calculation
```swift
func crc16(data: [UInt8]) -> UInt16 {
    var crc: UInt16 = 0xFFFF
    for byte in data {
        crc ^= UInt16(byte)
        for _ in 0..<8 {
            crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xA001 : crc >> 1)
        }
    }
    return crc
}
```

---

## Known Opcodes

### Opcode 0x6B (Unknown - Contains Orientation)
- **Length**: 202 bytes
- **Orientation Data**: Bytes 64-71 (8 bytes)
- **Format**: 4x 16-bit signed integers (normalized)
- **Quaternion**: `(w, x, y, z)` where `w` is scalar component

### Opcode 0x00 (Unknown)
- **Length**: 254 bytes
- **Purpose**: Unknown large data message
- **Structure**: Unknown

### Opcode 0x34 (Unknown - Contains Orientation)
- **Length**: 12 bytes
- **Orientation Data**: Bytes 0-7 (8 bytes)
- **Format**: 4x 16-bit signed integers (normalized)
- **Quaternion**: `(w, x, y, z)` where `w` is scalar component

### Opcode 0x03 (State Change)
- **Length**: 94 bytes
- **Turn Data**: Byte 34 (turn that was applied)
- **Cube State**: Bytes 7-33 (27 bytes)
- **Battery**: Byte 35 (0-100)
- **Previous Moves**: Bytes 36-90 (55 bytes)
- **Needs ACK**: Byte 91 (0/1)

### Opcode 0x02 (Cube Hello)
- **Length**: 38 bytes
- **Cube State**: Bytes 7-33 (27 bytes)
- **Battery**: Byte 35 (0-100)

### Opcode 0x04 (Sync Confirmation)
- **Length**: 38 bytes
- **Cube State**: Bytes 7-33 (27 bytes)
- **Battery**: Byte 35 (0-100)

---

## Turn Detection

Turn information is encoded in State Change messages (opcode 0x03):

| Byte | Move | Description |
|------|------|-------------|
| `0x1` | L' | Left face counter-clockwise |
| `0x2` | L | Left face clockwise |
| `0x3` | R' | Right face counter-clockwise |
| `0x4` | R | Right face clockwise |
| `0x5` | D' | Down face counter-clockwise |
| `0x6` | D | Down face clockwise |
| `0x7` | U' | Up face counter-clockwise |
| `0x8` | U | Up face clockwise |
| `0x9` | F' | Front face counter-clockwise |
| `0xA` | F | Front face clockwise |
| `0xB` | B' | Back face counter-clockwise |
| `0xC` | B | Back face clockwise |

---

## Orientation Data

### Location
Orientation data is found in **two different opcodes**:

1. **Opcode 0x6B**: Bytes 64-71 (8 bytes)
2. **Opcode 0x34**: Bytes 0-7 (8 bytes)

### Format
- **Data Type**: 4x 16-bit signed integers
- **Normalization**: Divide by 32767 to get range [-1.0, 1.0]
- **Byte Order**: Little-endian
- **Component Order**: `(w, x, y, z)` where `w` is scalar

### Parsing Implementation
```swift
func parseQuaternion(from message: [UInt8], opcode: Int) -> SIMD4<Float>? {
    switch opcode {
    case 0x6B:
        guard message.count >= 72 else { return nil }
        let bytes = message[64..<72]
        return parseQuaternionFromInt16(Array(bytes))
        
    case 0x34:
        guard message.count >= 8 else { return nil }
        let bytes = message[0..<8]
        return parseQuaternionFromInt16(Array(bytes))
        
    default:
        return nil
    }
}

func parseQuaternionFromInt16(_ bytes: [UInt8]) -> SIMD4<Float> {
    return bytes.withUnsafeBufferPointer { buffer in
        buffer.withMemoryRebound(to: Int16.self) { int16Ptr in
            SIMD4(
                Float(int16Ptr[3]) / 32767.0,  // w
                Float(int16Ptr[0]) / 32767.0, // x  
                Float(int16Ptr[1]) / 32767.0, // y
                Float(int16Ptr[2]) / 32767.0  // z
            )
        }
    }
}
```

### Quaternion Validation
- **Magnitude**: Should be close to 1.0 (unit quaternion)
- **Range**: Components should be in [-1.0, 1.0]
- **Filter**: Remove NaN, infinite, or zero-magnitude quaternions

---

## BLE Implementation Challenges

### Packet Fragmentation
The cube's BLE implementation creates significant fragmentation challenges:

#### Root Causes
1. **MTU Mismatch**: Cube sends 43-byte encrypted messages, but BLE MTU is typically 23 bytes
2. **OS Buffering**: iOS/macOS BLE stacks buffer and recombine packets arbitrarily
3. **Hardware Timing**: Cube's BLE chip sends data in hardware-determined chunks

#### Fragmentation Statistics
- **94.1%** of packets have NO 0xFE header at 16-byte boundaries
- **14 different offsets** where 0xFE headers appear
- **Most common offset**: 13 bytes (14.3% of valid headers)

### Solution: Byte-by-Byte Search
```swift
private func tryOptimalByteByByteResync() -> DecryptionResult {
    let maxSearchBytes = min(self.rxBuffer.count, 64)
    
    // Check EVERY byte offset, not just 16-byte boundaries
    for offset in 0..<maxSearchBytes {
        if offset + 16 <= self.rxBuffer.count {
            let block = self.rxBuffer[offset..<offset+16]
            if let decrypted = decryptBlock(block) {
                if decrypted[0] == 0xFE {
                    // Found valid header at this offset!
                    return .success(offset: offset, message: message)
                }
            }
        }
    }
}
```

---

## Unknown Areas

### Opcode 0x6B and 0x00
- **Purpose**: Unknown what these messages represent
- **Frequency**: Unknown when they are sent
- **Triggers**: Unknown what causes these messages
- **Additional Data**: Unknown meaning of remaining bytes

### Opcode 0x34 Context
- **Purpose**: Unknown why this small message contains orientation data
- **Relationship**: Unknown how it relates to 0x6B messages
- **Priority**: Unknown which opcode takes precedence

### Message Timing
- **Frequency**: Unknown message send rates
- **Triggers**: Unknown what causes each message type
- **Sequencing**: Unknown message ordering rules

### Cube State Format (Bytes 7-33)
- **Structure**: 27 bytes of cube state data
- **Encoding**: Unknown how cube state is represented
- **Fields**: Unknown what specific information is included

### Previous Moves (Bytes 36-90)
- **Format**: 55 bytes of turn history
- **Encoding**: Unknown how previous moves are stored
- **Limit**: Unknown maximum number of stored moves

---

## Implementation Notes

### Decryption Strategy
1. **Always use byte-by-byte search** for 0xFE headers
2. **Handle fragmentation** by checking offsets 0-63
3. **Validate CRC16** before processing
4. **Drop bytes incrementally** when decryption fails

### Quaternion Processing
1. **Parse from both opcodes** (0x6B and 0x34)
2. **Validate quaternion magnitude** (~1.0)
3. **Filter invalid quaternions** (NaN, zero magnitude)
4. **Convert to Euler angles** if needed for display

### Error Handling
1. **Log all decryption attempts** with approach details
2. **Track success rates** for different resync strategies
3. **Handle malformed packets** gracefully
4. **Implement timeouts** for infinite loops

### Performance Optimization
1. **Limit search range** to first 64 bytes
2. **Cache successful offsets** for future messages
3. **Batch process** multiple encrypted blocks
4. **Use efficient data structures** for buffer management

---

## References

- [Original QiYi Protocol Documentation](contrib/qiyi_smartcube_protocol/README.md)
- [BLE Packet Analysis Results](wireshark/XMD-Tornado-V4-i-0A87-raw.ble_analysis.json)
- [Deep Fragmentation Analysis](wireshark/XMD-Tornado-V4-i-0A87-raw.deep_analysis.json)
- [Orientation Analysis](wireshark/decrypted_output.all_opcode_analysis.json)

---

## Contributing

This specification is based on reverse engineering of real cube data. If you discover new information or corrections, please submit pull requests to improve this documentation.

**Areas needing investigation:**
- Opcode 0x6B and 0x00 message purposes
- Cube state encoding format
- Message timing and sequencing
- Additional data fields in known messages

---

*Last Updated: January 26, 2026*
