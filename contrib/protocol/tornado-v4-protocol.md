# XMD Tornado V4 Bluetooth Protocol Specification

## Overview

This document describes the reverse-engineered Bluetooth Low Energy (BLE) protocol used by the XMD Tornado V4 smart cube.

## Device Information

- **Device Name**: XMD-TornadoV4-i-XXXX (where XXXX is last 4 hex digits of MAC)
- **MAC Address Format**: CC:A6:00:00:XX:XX
- **Bluetooth Version**: 4.x (DPLE Supported, 2MPHY Unsupported)

## Encryption

- **Algorithm**: AES-128 ECB
- **Key**: `57 B1 F9 AB CD 5A E8 A7 9C B9 8C E7 57 8C 51 08`

## GATT Services

### Generic Access Service (0x0001-0x0007)
Standard BLE service for device name and appearance.

### Generic Attribute Service (0x0008-0x000B)
Standard GATT service with Service Changed characteristic.

### Custom Service (0x000C-0x0011)
- **UUID**: `5833FF01-9B8B-5191-6142-22A4536EF123`
- **Characteristics**:
  - `5833FF02-...` (0x000E) - Write
  - `5833FF03-...` (0x0010) - Notify

### Main Data Service - FFF0 (0x0012-0xFFFF)
- **UUID**: `0000FFF0-0000-1000-8000-00805F9B34FB`

#### Characteristics:

| Handle | UUID | Properties | Description |
|--------|------|------------|-------------|
| 0x0014 | FFF4 | Read | Device info / Status |
| 0x0017 | FFF5 | Write | Commands |
| 0x001A | FFF6 | Write No Response, Notify | **Main data channel** |
| 0x001E | FFF7 | Read | Unknown |

## Protocol Flow

### 1. Connection Handshake

After connecting and enabling notifications on FFF6 (handle 0x001B):

1. **Client sends** (32 bytes encrypted):
   ```
   3C CD 26 49 2D 58 DC 2E C2 94 50 54 55 1B A8 DC
   5B B6 C7 B2 A5 BD D5 36 23 85 BE 36 EC 03 B4 E7
   ```

2. **Cube responds** (48 bytes encrypted):
   ```
   51 39 6A 7F 3A E2 EA 7D CF B4 15 3A A3 5E 09 C1
   AC 9E D7 64 B2 F7 47 48 51 89 62 F6 B5 F5 8D 9C
   A5 33 7F 4E BD FB 50 BB 34 40 97 CB C6 C7 88 7F
   ```

3. **Client sends** (16 bytes encrypted):
   ```
   63 59 A6 DE E8 A5 4A CD 3C 2D 53 FE 16 45 1D 3B
   ```

4. **Cube responds** (16 bytes encrypted):
   ```
   8F 4C 21 A6 BD 74 7F 11 37 C7 7D AF 1B 68 AB 76
   ```

### 2. Move Notifications

After handshake, cube sends 16-byte encrypted notifications for each move/state change.

Example encrypted notifications:
```
AA 13 43 DF 96 1F EC FD 57 59 61 76 B2 11 6C 92
96 EF 2A 8E F4 B6 D2 23 8A D9 42 2C 0D BB C5 0A
58 71 13 50 2A 1C F8 BD 18 02 5B 19 EE 14 A3 F6
...
```

## Decrypted Data Format

All data is AES-128 ECB encrypted in 16-byte blocks.

### Message Types

| Prefix | Type | Description |
|--------|------|-------------|
| `FE` | Command/Handshake | Connection setup and commands |
| `EE` | Move/State | Move history and cube state |
| `CC` | Gyroscope | Orientation/sensor data |

### Handshake Protocol

#### Step 1: Client Hello (32 bytes)
```
FE 15 F0 AE 02 00 00 24 01 00 02 27 1E 87 0A 00
00 A6 CC 3E 6E 00 00 00 00 00 00 00 00 00 00 00
```
- Bytes 0-1: `FE 15` - Command header
- Bytes 7-10: `24 01 00 02` - Protocol version?
- Bytes 13-18: `87 0A 00 00 A6 CC` - MAC address (reversed)

#### Step 2: Cube Response (48 bytes)
```
FE 26 02 0F C9 70 39 03 54 43 55 20 13 11 42 41
12 35 44 33 53 00 25 12 00 00 51 10 34 31 52 54
22 24 00 5E D2 27 00 00 00 00 00 00 00 00 00 00
```
- Bytes 0-1: `FE 26` - Response header
- Bytes 2-6: `02 0F C9 70 39` - Session token
- Byte 7: `03` - Unknown (protocol version?)
- **Bytes 8-20: Cube state encoding** (see below)
- Bytes 21-35: Additional state/edge data
- Bytes 36-37: `5E D2` - Possibly battery/status
- Byte 38: `27` = 39 decimal - Move counter?

### Cube State Encoding

**Solved cube state (bytes 7-35 from handshake response):**
```
33 33 33 33 13 11 11 11 11 44 44 44 44 24 22 22 22 22 00 00 00 00 50 55 55 55 55 00 5A
```

Pattern analysis:
- `33 33 33 33` + `13` - Corner positions? (4 bytes + orientation nibble)
- `11 11 11 11` - Edge group 1
- `44 44 44 44` + `24` - Corner group 2
- `22 22 22 22` - Edge group 2
- `00 00 00 00` - Padding/unused
- `50 55 55 55 55` - Additional state
- `5A` - Checksum or status byte

**Scrambled cube state (from first capture):**
```
54 43 55 20 13 11 42 41 12 35 44 33 53 00 25 12 00 00 51 10 34 31 52 54 22 24 00 5E
```

The solved state has repeating patterns (33, 11, 44, 22, 55) indicating all pieces in home positions with zero orientation.

#### Step 3: Client Acknowledgment (16 bytes)
```
FE 09 02 0F C9 70 39 4B 6E 00 00 00 00 00 00 00
```
- Bytes 0-1: `FE 09` - Ack header
- Bytes 2-6: `02 0F C9 70 39` - Session token (from response)

#### Step 4: Cube Ready (16 bytes)
```
EE 10 00 C0 00 2E FF 00 00 00 FF 00 00 00 2D CD
```
- Initial state message

### Move Messages (EE prefix)

Format: `EE 10 SS MM MM TT TT MM MM TT TT ...`

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 1 | `EE` - Message type |
| 1 | 1 | `10` - Subtype |
| 2 | 1 | Sequence number |
| 3-4 | 2 | Move 1 data (little-endian) |
| 5-6 | 2 | Timestamp 1 |
| 7-8 | 2 | Move 2 data |
| 9-10 | 2 | Timestamp 2 |
| ... | ... | More moves |
| 14-15 | 2 | Checksum |

Example decoded:
```
EE 10 01 50 01 3F 00 C0 00 2E FF 00 00 00 DB 97
       ^^ seq=1
          ^^^^^ move data
                ^^^^^ timestamp
```

### Gyroscope Messages (CC prefix)

Format: `CC 10 SS GX GX 5E 02 GY GY GZ GZ ...`

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 1 | `CC` - Message type |
| 1 | 1 | `10` - Subtype |
| 2 | 1 | Sequence number |
| 3-4 | 2 | Gyro X (signed 16-bit) |
| 5-6 | 2 | Constant `5E 02` (606 decimal) |
| 7-8 | 2 | Gyro Y |
| 9-10 | 2 | Gyro Z |
| ... | ... | Additional sensor data |

### Move Encoding

Each EE message contains a sliding window of recent moves (up to 5 moves). Format is little-endian 16-bit values.

**Reference orientation (after sync):**
- **White** face = Up (U)
- **Green** face = Front (F)
- **Red** face = Right (R)
- **Yellow** face = Down (D)
- **Blue** face = Back (B)
- **Orange** face = Left (L)

**Move byte encoding (UPPER nibble of byte[3] in move pair):**

| Byte | Move | Description | Verified |
|------|------|-------------|----------|
| 0x1 | L' | Left (orange) CCW | |
| 0x2 | L | Left (orange) CW | ✓ |
| 0x3 | R' | Right (red) CCW | |
| 0x4 | R | Right (red) CW | ✓ |
| 0x5 | D' | Down (yellow) CCW | |
| 0x6 | D | Down (yellow) CW | ✓ |
| 0x7 | B' | Back (blue) CCW | |
| 0x8 | B | Back (blue) CW | (pattern) |
| 0x9 | F' | Front (green) CCW | |
| 0xA | F | Front (green) CW | ✓ |
| 0xB | U' | Up (white) CCW | |
| 0xC | U | Up (white) CW | ✓ |

**Verified from captures:**
- 0xC = U (white CW) — from solved cube capture
- 0xA = F (green CW) — from green-yellow-orange capture
- 0x6 = D (yellow CW) — from green-yellow-orange capture
- 0x2 = L (orange CW) — from green-yellow-orange capture
- 0x4 = R (red CW) — from red-blue capture
- 0x8 = B (blue CW) — assumed by pattern (odd=CCW, even=CW)

**16-bit value format:**
```
byte[3]     byte[4]
[MMTT]      [TTTT]
  ^           ^
  |           +-- Timestamp (lower 8 bits)
  +-- Upper nibble = Move type (0x1-0xC)
      Lower nibble = Timestamp (upper 4 bits)
```

**Example from capture:**
```
byte[3]=0xA0, byte[4]=0x05
  0xA0 = 1010 0000
         ^^^^ ^^^^
         move  ts_hi
  Move = 0xA = F (green CW)
```

### Gyroscope Data (CC messages)

Real-time orientation data from cube's IMU sensor.

| Offset | Size | Description | Range |
|--------|------|-------------|-------|
| 3-4 | 2 | Gyro X | -32768 to 32767 |
| 5-6 | 2 | Constant (0x025E = 606) | Fixed |
| 7-8 | 2 | Gyro Y | -32768 to 32767 |
| 9-10 | 2 | Gyro Z | -32768 to 32767 |

**Sample readings:**
```
Gyro X: -2300, Y: -426, Z: -685
Gyro X: 27653, Y: -403, Z: -613
Gyro X: -7419, Y: -409, Z: -612
```

Values represent angular velocity or orientation angles.

### Checksum

**Algorithm**: CRC-16 MODBUS ✓ (verified)
- **Polynomial**: 0x8005 (reflected: 0xA001)
- **Initial value**: 0xFFFF
- **Input**: Bytes 0-13 (first 14 bytes of decrypted message)
- **Output**: Bytes 14-15 (little-endian)

```python
def crc16_modbus(data):
    crc = 0xFFFF
    for byte in data:
        crc ^= byte
        for _ in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ 0xA001
            else:
                crc >>= 1
    return crc
```

## Advertising Data

### Manufacturer Specific Data (0xFF)
- Company ID: 0x0504
- Data includes MAC address and status bytes

### Scan Response
- Complete Local Name: "XMD-TornadoV4-i-XXXX"
- Slave Connection Interval Range: 0x0010-0x0020

## References

- Captured data (scrambled): `contrib/data/XMD-Tornado-V4-i-0A87-raw.txt`
- BTSnoop log (scrambled): `contrib/data/XMD-Tornado-V4-i-0A87-btsnoop.log`
- BTSnoop log (solved cube): `contrib/data/XMD-Tornado-V4-i-0A87-solved-btsnoop.log`
- Green/Yellow/Orange capture: `contrib/data/XMD-Tornado-V4-i-0A87-green-yellow-orange-raw.txt`
- Red/Blue capture: `contrib/data/XMD-Tornado-V4-i-0A87-red-blue-raw.txt`
- Decryption script: `contrib/decrypt_tornado.py`
- Analysis script: `contrib/analyze_red.py`
