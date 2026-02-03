# Tornado V4 Smart Cube Bluetooth Protocol Specification

## Overview

This document describes the reverse-engineered Bluetooth Low Energy (BLE) protocol used by the Tornado V4 family of smart cubes (XMD/QiYi). Protocol analysis based on Wireshark captures and app behavior.

**Protocol Version:** 1.1  
**Last Updated:** February 2025  
**Status:** VERIFIED

## Device Information

- **Device Name Patterns**: 
  - `XMD-TornadoV4-i-XXXX` (XMD variant)
  - `QY-QYSC-XXX` (QiYi variant)
- **Bluetooth Version**: 4.x (DPLE Supported)

## Encryption

- **Algorithm**: AES-128 ECB
- **Block Size**: 16 bytes
- **Multi-block**: Messages >16 bytes are encrypted block-by-block (each 16 bytes independently)

### Known Encryption Keys

Keys are derived from device name suffix:

| Suffix | Key (hex) |
|--------|-----------|
| Default | `57 B1 F9 AB CD 5A E8 A7 9C B9 8C E7 57 8C 51 08` |
| Alternative | `11 22 33 44 55 66 77 88 99 00 aa bb cc dd ee ff` |
| 5HH, DFZ | `11 04 19 8a fc e0 38 5f 11 04 19 8a fc e0 38 5f` |

**Important**: Handshake responses (FE 26) are 48 bytes = 3 blocks. Must decrypt all 3 blocks to get full facelet state.

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

### Alternative Service (Nordic UART)
Some variants use Nordic UART Service:
- **Service UUID**: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- **TX (Write)**: `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
- **RX (Notify)**: `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`

## Message Types Summary

| Prefix | Type | Direction | Description |
|--------|------|-----------|-------------|
| `FE 15` | Handshake Hello | App → Cube | Initial connection request |
| `FE 26` | Handshake Response | Cube → App | Connection established + cube state (byte[2]=0x02) |
| `FE 26` | Set State Command | App → Cube | Overwrite cube's internal state (byte[2]=0x04) |
| `FE 26` | Set State Response | Cube → App | Confirms state change (byte[2]=0x04) |
| `FE 09` | Handshake ACK | App → Cube | Acknowledge connection |
| `EE 10` | Move Data | Cube → App | Move history (3 slots) |
| `DD 10` | Move Marker | Cube → App | Move confirmation/status |
| `DD 09` | Move ACK | App → Cube | Acknowledge DD message (echoes data) |
| `CC 10` | Gyroscope | Cube → App | IMU orientation data (quaternion) |

### FE 26 Byte[2] Flag Meanings
| Value | Direction | Meaning |
|-------|-----------|---------|
| 0x02 | Cube → App | Handshake response (connection) |
| 0x04 | Both | Set state command/response |

## Protocol Flow

### 1. Connection Handshake

After connecting and enabling notifications on FFF6 (handle 0x001B):

#### Step 1: Client Hello (32 bytes encrypted → 32 bytes)
```
FE 15 F0 AE 02 00 00 24 01 00 02 27 1E 87 0A 00
00 A6 CC [CRC16] 00 00 00 00 00 00 00 00 00 00
```
- Bytes 0-1: `FE 15` - Command header
- Bytes 2-6: `F0 AE 02 00 00` - Client identifier
- Bytes 7-12: `24 01 00 02 27 1E` - Protocol version/flags
- Bytes 13-18: MAC address (reversed) - `CC A6 00 00 XX XX` becomes `XX XX 00 00 A6 CC`
- Bytes 19-20: CRC-16 MODBUS of bytes 0-18

#### Step 2: Cube Response (48 bytes encrypted → 48 bytes)
```
FE 26 02 0F C9 70 39 [27 bytes facelets] [status] [CRC16]
```
- Bytes 0-1: `FE 26` - Response header
- Bytes 2-6: Session token (echo back in ACK)
- **Bytes 7-33: Cube facelet state** (27 bytes = 54 nibbles, see Facelet Encoding)
- Byte 34: Unknown (often 0x00)
- **Byte 35: Battery level (0-100%)** - e.g., 0x5E = 94%
- Bytes 36-37: Unknown (possibly timestamp/counter)
- **Byte 37: Move counter** - total moves since power-on
- Bytes 38-45: Padding (zeros)
- Bytes 46-47: CRC-16

#### Step 3: Client Acknowledgment (16 bytes encrypted)
```
FE 09 [session token from step 2] [CRC16] 00...
```
- Bytes 0-1: `FE 09` - ACK header
- Bytes 2-6: Session token (copied from cube response)
- Bytes 7-8: CRC-16 MODBUS
- Bytes 9-15: Zero padding

#### Step 4: Cube Ready
Cube begins sending move notifications (EE/DD messages).

### 2. Reset Cube State (Set State Command)

**Discovery**: The FE 26 opcode serves dual purpose - it's both the handshake response AND can be sent FROM app TO cube to overwrite the cube's internal state!

#### Reset Command Format (32 bytes encrypted)
```
FE 26 04 [session] [27 bytes solved facelets] 00...
```

**Solved state facelets (protocol order URFDLB)**:
```
33 33 33 33 13  -- U face (all 3s) + R[0]=1
11 11 11 11     -- R face (all 1s)
44 44 44 44 24  -- F face (all 4s) + D[0]=2
22 22 22 22     -- D face (all 2s)
00 00 00 00 50  -- L face (all 0s) + B[0]=5
55 55 55 55     -- B face (all 5s)
```

This command tells the cube "your current state is now THIS" - used by official app's Reset button.

**Important**: After sending reset command:
1. Cube responds with FE 26 containing byte[2]=0x04 and the new facelets
2. **Sequence counter resets to 0** - must reset sequence tracking
3. Next EE message will have seq=0 (not continuing from previous)

## Facelet State Encoding

### Nibble Values → Face Colors
| Value | Face | Color |
|-------|------|-------|
| 0 | L (Left) | Orange |
| 1 | R (Right) | Red |
| 2 | D (Down) | Yellow |
| 3 | U (Up) | White |
| 4 | F (Front) | Green |
| 5 | B (Back) | Blue |

### Facelet Packing
27 bytes contain 54 facelets (4 bits each):
- Byte[n] low nibble = facelet[n*2]
- Byte[n] high nibble = facelet[n*2+1]

### Face Order

**VERIFIED**: XMD Tornado V4 uses **URFDLB** order (Up, Right, Front, Down, Left, Back).

Previous documentation incorrectly stated LRDUFB - this was corrected based on BLE capture analysis of Reset command.

Each face has 9 facelets in row-major order (top-left to bottom-right).

### Solved State Pattern
```
Bytes 7-33 from FE 26 response for solved cube (URFDLB order):
33 33 33 33 13 11 11 11 11 44 44 44 44 24 22 22 22 22 00 00 00 00 50 55 55 55 55

Breakdown:
33 33 33 33 13  = U face (9× value 3) + R[0]
11 11 11 11     = R face (9× value 1)
44 44 44 44 24  = F face (9× value 4) + D[0]
22 22 22 22     = D face (9× value 2)
00 00 00 00 50  = L face (9× value 0) + B[0]
55 55 55 55     = B face (9× value 5)
```

## Move Messages

### EE Message Format (16 bytes)
Primary move notification containing 3-move history buffer.

```
EE 10 SS M0 T0 T0 XX M1 T1 T1 XX M2 T2 T2 XX [CRC16]
```

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 1 | `EE` - Message type |
| 1 | 1 | `10` - Subtype |
| 2 | 1 | Sequence number ⚠️ (see below) |
| 3 | 1 | **Slot 0**: Move byte (newest move, seq=N) |
| 4-5 | 2 | Slot 0: Timestamp |
| 6 | 1 | Unknown |
| 7 | 1 | **Slot 1**: Move byte (seq=N-1) |
| 8-9 | 2 | Slot 1: Timestamp |
| 10 | 1 | Unknown |
| 11 | 1 | **Slot 2**: Move byte (oldest, seq=N-2) |
| 12-13 | 2 | Slot 2: Timestamp |
| 14-15 | 2 | CRC-16 MODBUS |

### Sequence Number ⚠️ CRITICAL

**VERIFIED**: Sequence number range is **0-99 (mod 100)**, NOT 0-255!

The sequence number wraps from 99 → 0. This is crucial for proper move tracking during fast solving.

#### Wraparound Handling Algorithm

```python
def calculate_seq_diff(seq, last_seq):
    diff = seq - last_seq
    if diff > 50:
        seq_diff = diff - 100  # e.g., last=1, seq=99 → diff=98 → seq_diff=-2
    elif diff < -50:
        seq_diff = 100 + diff  # e.g., last=99, seq=0 → diff=-99 → seq_diff=1 ✓
    else:
        seq_diff = diff
    return seq_diff
```

**Example**: When sequence goes 99 → 0:
- `diff = 0 - 99 = -99`
- Since `-99 < -50`, apply: `seq_diff = 100 + (-99) = 1`
- Result: 1 new move correctly detected

### Move Byte Extraction
Move type is in the move byte (some variants use upper nibble):
```python
move_byte = data[3]  # or data[7], data[11]
move_type = move_byte & 0x0F  # or (move_byte >> 4) for some variants
```

### DD Message Format (16 bytes)
Move confirmation/marker message. Similar structure to EE.

```
DD 10 SS M0 T0 T0 XX M1 T1 T1 XX M2 T2 T2 XX [CRC16]
```

**Key Discovery**: DD messages appear to confirm/mark move completion:
- First DD after moves = normal confirmation
- **Second DD with same sequence number = SOLVED indicator!**

### DD 09 ACK Message (App → Cube)
The official app sends DD 09 to acknowledge DD messages from cube:

```
DD 09 SS M0 T0 T0 XX [CRC16] 00 00 00 00 00 00 00
```

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 1 | `DD` - Message type |
| 1 | 1 | `09` - ACK opcode |
| 2 | 1 | Sequence number (echo from cube's DD) |
| 3-6 | 4 | Move data (echo from cube's DD) |
| 7-8 | 2 | CRC-16 MODBUS |
| 9-15 | 7 | Zero padding |

**Note**: This ACK may be optional - functionality works without it.

### Sequence Number Handling

Use sequence difference to determine new moves:
- diff=1 → process slot 0 only
- diff=2 → process slots 0 and 1 (oldest first!)
- diff=3+ → process all slots (cap at 3)
- Process from **oldest to newest** (slot 2 → 1 → 0)

```python
slots_to_process = min(max(seq_diff, 0), 3)
for i in range(slots_to_process - 1, -1, -1):  # oldest to newest
    move_code = slots[i]
    if move_code != 0x00:
        process_move(move_code)
```

## Move Encoding Table (VERIFIED ✓)

| Byte | Move | Face | Direction |
|------|------|------|-----------|
| 0x0 | - | None | No move |
| 0x1 | L' | Left (Orange) | Counter-clockwise |
| 0x2 | L | Left (Orange) | Clockwise |
| 0x3 | R' | Right (Red) | Counter-clockwise |
| 0x4 | R | Right (Red) | Clockwise |
| 0x5 | D' | Down (Yellow) | Counter-clockwise |
| 0x6 | D | Down (Yellow) | Clockwise |
| 0x7 | U' | Up (White) | Counter-clockwise |
| 0x8 | U | Up (White) | Clockwise |
| 0x9 | F' | Front (Green) | Counter-clockwise |
| 0xA | F | Front (Green) | Clockwise |
| 0xB | B' | Back (Blue) | Counter-clockwise |
| 0xC | B | Back (Blue) | Clockwise |

**Pattern**: Odd values = CCW ('), Even values = CW

### Slice Move Detection
Middle layer moves produce two face moves in rapid succession:
- **M** (Middle): R' + L (0x3 + 0x2)
- **M'**: L' + R (0x1 + 0x4)
- **S** (Standing): F' + B (0x9 + 0xC)
- **S'**: F + B' (0xA + 0xB)
- **E** (Equator): D + U' (0x6 + 0x7)
- **E'**: U + D' (0x8 + 0x5)

Use ~150ms time window to combine consecutive opposite-face moves into slice notation.

## Gyroscope Messages (CC)

### Format (16 bytes)
```
CC 10 SS TS TS XX QW QW QX QX QY QY QZ QZ [CRC16]
```

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 1 | `CC` - Message type |
| 1 | 1 | `10` - Subtype |
| 2 | 1 | Sequence number |
| 3-4 | 2 | Timestamp (little-endian) |
| 5 | 1 | Constant 0x5E or flag |
| 6-7 | 2 | Quaternion W (signed 16-bit, **big-endian**) |
| 8-9 | 2 | Quaternion X |
| 10-11 | 2 | Quaternion Y |
| 12-13 | 2 | Quaternion Z |
| 14-15 | 2 | CRC-16 |

**Quaternion Interpretation**:
- Values are unit quaternion components × 1000
- Big-endian byte order (MSB first)
- Example: `FE 56` = -426 (not 65110)
- Typical range: -1000 to +1000 per component
- sqrt(w² + x² + y² + z²) ≈ 1000

### Gyroscope Calibration

**IMPORTANT**: There is NO protocol-level gyroscope calibration command. The cube sends raw IMU orientation data, and calibration must be handled application-side.

**Axis Mapping** (Cube sensor → SceneKit):
```
SceneKit.X = -Cube.Z  (OR axis: Orange-Red)
SceneKit.Y = +Cube.Y  (WY axis: White-Yellow)
SceneKit.Z = -Cube.X  (GB axis: Green-Blue)
```

**Quaternion Transformation**:
```swift
let mappedQuat = simd_quatf(ix: -rawZ, iy: rawY, iz: -rawX, r: rawW)
```

**Initial Orientation Correction**:
To align virtual cube with physical orientation (white up, green front):
```swift
let rotateX = simd_quatf(angle: Float.pi / 2, axis: simd_float3(1, 0, 0))   // +90° around X
let rotateY = simd_quatf(angle: Float.pi / 2, axis: simd_float3(0, 1, 0))   // +90° around Y
let baseRotation = rotateY * rotateX
```

## Checksum

**Algorithm**: CRC-16 MODBUS
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

## Reference Orientation

Standard cube orientation (after sync):
- **White** = Up (U)
- **Green** = Front (F)
- **Orange** = Left (L)
- **Red** = Right (R)
- **Blue** = Back (B)
- **Yellow** = Down (D)

### Opposite Face Pairs
- White (U) ↔ Yellow (D)
- Green (F) ↔ Blue (B)
- Orange (L) ↔ Red (R)

## Implementation Notes

### Fast Move Handling
When user makes rapid moves, multiple moves may arrive in single EE message:
1. Calculate sequence difference: `diff = current_seq - last_seq`
2. Handle wraparound using mod 100 algorithm (NOT mod 256!)
3. Cap at 3 (max slots available)
4. Process moves oldest-to-newest to maintain correct order

### Animation Queue
To prevent animation lag from dropping moves:
- Queue incoming moves instead of blocking
- Process queue independently of animation state
- Never filter "duplicate" moves by byte value (consecutive same moves are valid!)

### Edge Rotation Behavior
When implementing cube state updates for face rotations:
- **U face (clockwise from above):** Edges cycle F → L → B → R
- **D face (clockwise from below):** Edges cycle F → R → B → L
- **E slice (follows D direction):** Middle row cycles F → R → B → L (clockwise)
- **y rotation (follows U direction):** Whole cube rotates F → L → B → R (clockwise)

Note: Consistent with standard Rubik's cube notation where clockwise is relative to the face orientation.

### Multi-Block Decryption
FE 26 responses are 48 bytes (3 × 16-byte blocks):
```python
def decrypt(data):
    result = bytearray()
    for i in range(0, len(data), 16):
        block = data[i:i+16]
        if len(block) == 16:
            result.extend(decrypt_block(block))
    return bytes(result)
```

## Advertising Data

### Manufacturer Specific Data (0xFF)
- Company ID: 0x0504
- Data includes MAC address and status bytes

### Scan Response
- Complete Local Name: "XMD-TornadoV4-i-XXXX" or similar
- Slave Connection Interval Range: 0x0010-0x0020

## Known Issues & Gotchas

1. **Sequence wraparound**: MUST use mod 100, not mod 256
2. **Move slots**: Only process `seq_diff` number of slots, not all 3
3. **Face order**: XMD Tornado V4 uses URFDLB (verified from BLE capture)
4. **Encryption**: 20-byte messages become 16-byte decrypted payload
5. **Multi-block**: FE 26 responses need 3-block decryption

## Remaining Unknowns

### Unexplored Characteristics
- **FFF4** (Read): Device info/status - format unknown
- **FFF5** (Write): Commands - what commands it accepts unknown
- **FFF7** (Read): Purpose completely unknown
- **Custom service 5833FF01**: Possibly firmware updates or advanced features

### Partially Understood
- **Timestamp format**: Small values (0-63 typical), likely milliseconds modulo some value
- **Move counter in FE 26**: byte[37] appears to be move count, needs verification
- **Bytes 34/36 in FE 26**: Purpose unclear, possibly status flags

### Needs Verification
- Battery level interpretation (byte[35] = percentage) - needs multiple captures at different battery levels
- 180° double moves encoding - are they two consecutive moves or special encoding?
- Error handling - what happens on invalid commands?

## Tools

### BLE Capture Decoder
A Python decoder script is available at `contrib/tools/decode_ble_capture.py`:

```bash
# Decode capture file (excludes gyroscope messages)
python3 contrib/tools/decode_ble_capture.py capture.txt

# Include all messages (gyroscope, etc.)
python3 contrib/tools/decode_ble_capture.py capture.txt -a

# Decode single hex string
python3 contrib/tools/decode_ble_capture.py -x "90 03 BC A1 ..."

# Use alternative key
python3 contrib/tools/decode_ble_capture.py capture.txt -k alt
```

Requires: `pip install cryptography` or `pip install pycryptodome`

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-01 | Initial documentation |
| 1.1 | 2025-02 | Corrected sequence range (0-99 mod 100), verified move encoding, added face order variants, added wraparound algorithm, corrected edge rotation directions for U/D/E/y |
| 1.2 | 2025-02 | Verified face order as URFDLB (not LRDUFB), added gyroscope calibration notes, added BLE decoder tool |
