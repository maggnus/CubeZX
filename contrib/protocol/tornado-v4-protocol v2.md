## XMD Tornado V4 Bluetooth Protocol Specification (v2)

### 1. Overview

This document describes the **reverse-engineered Bluetooth Low Energy (BLE) protocol** used by the **XMD Tornado V4 smart cube**.
It is based on:
- Live captures from the official mobile app
- BTSnoop/HCI logs
- Decrypted payload analysis
- Behavior of the CubeZX companion app

All details here are **empirical**, not vendor-provided. Field names and semantics are best-effort.

---

### 2. Device Information

- **Device Name**: `XMD-TornadoV4-i-XXXX`
  - `XXXX` = last 4 hex digits of MAC (`CC:A6:00:00:XX:XX`)
- **MAC Address Format**: `CC:A6:00:00:XX:XX`
- **Bluetooth Version**: 4.x (DPLE Supported, 2MPHY Unsupported)

At the BLE advertising level:
- Manufacturer specific data (`0xFF`) uses company ID `0x0504` and encodes MAC and status bits.
- Scan response contains the complete local name and connection interval hints.

---

### 3. Transport (GATT Services)

#### 3.1 Standard Services

- **Generic Access** (handles `0x0001–0x0007`)
  - Standard device name, appearance, etc.
- **Generic Attribute** (handles `0x0008–0x000B`)
  - Standard GATT service (Service Changed characteristic).

#### 3.2 Legacy Custom Service (5833FFxx)

This service appears on some firmware variants but is **not required** for standard cube control.

- **UUID**: `5833FF01-9B8B-5191-6142-22A4536EF123`
- **Characteristics**:
  - `5833FF02-...` (handle `0x000E`) – Write
  - `5833FF03-...` (handle `0x0010`) – Notify

#### 3.3 Main Data Service – FFF0

- **Service UUID**: `0000FFF0-0000-1000-8000-00805F9B34FB`
- **Characteristics**:

  | Handle | UUID | Properties                     | Description            |
  |--------|------|--------------------------------|------------------------|
  | 0x0014 | FFF4 | Read                           | Device info / status   |
  | 0x0017 | FFF5 | Write                          | Commands (rarely used) |
  | 0x001A | FFF6 | Write No Response, Notify      | **Main data channel**  |
  | 0x001E | FFF7 | Read                           | Unknown                |

**All smart-cube protocol traffic we care about flows over FFF6.**

---

### 4. Encryption

- **Algorithm**: AES-128 ECB (no IV, 16-byte blocks)
- **Key** (hex):

  `57 B1 F9 AB CD 5A E8 A7 9C B9 8C E7 57 8C 51 08`

- Every application-level message is first built as a **plaintext buffer**, then:
  - Padded with zero bytes to a multiple of 16 bytes
  - Encrypted using AES-128 ECB with the key above
  - Written to FFF6 (for client → cube) or sent as a notification (cube → client)

On the CubeZX side this is implemented in `AESCrypto` and invoked by the Tornado V4 adapter.

---

### 5. Message Types and Framing

All decrypted payloads start with a **type prefix byte** followed by a subtype or length.

| Prefix | Type       | Description                                  |
|--------|------------|----------------------------------------------|
| `FE`   | Command    | Handshake, connection setup, control frames  |
| `EE`   | Move/State | Move history, sequence number, CRC           |
| `CC`   | Gyroscope  | IMU / orientation data, sequence, CRC        |

Messages are typically **16 bytes decrypted** (single block) for `EE` and `CC`, and **32/48 bytes** for some `FE` handshake frames.

---

### 6. Connection Handshake

After connecting to the cube and enabling notifications on **FFF6 (handle `0x001A`)**, the client performs a 4-step handshake.

#### 6.1 Summary of Flow

1. **Client Hello (FE 15)** – app introduces itself and encodes the cube MAC.
2. **Cube Hello (FE 26)** – cube responds with session token and current cube state.
3. **Client Acknowledgment (FE 09)** – app acknowledges the session token.
4. **Cube Ready (EE 10)** – initial state message; after this, normal `EE` and `CC` traffic begins.

If step 3 is missing or malformed, the cube **repeats FE 26** periodically (log "spam") until it receives a valid `FE 09` ack.

#### 6.2 Step 1: Client Hello (FE 15)

Example **decrypted** 32-byte Client Hello:

```text
FE 15 F0 AE 02 00 00 24 01 00 02 27 1E 87 0A 00
00 A6 CC 3E 6E 00 00 00 00 00 00 00 00 00 00 00
```

- Bytes 0–1: `FE 15` – Command header (Client Hello)
- Bytes 2–6: `F0 AE 02 00 00` – Handshake/configuration fields (exact meaning unknown)
- Bytes 7–10: `24 01 00 02` – Protocol version / capabilities (inferred)
- Bytes 11–12: `27 1E` – Additional flags / unknown
- **Bytes 13–18**: `87 0A 00 00 A6 CC` – MAC address in **reversed order**
  - Matches `CC:A6:00:00:0A:87` when reversed
- Remaining bytes are **zero padding** to reach 32 bytes before encryption.

In CubeZX, the MAC bytes are constructed as:
- Base: `CC A6 00 00`
- Suffix: derived from the last four hex characters of the device name `XMD-TornadoV4-i-XXXX`.
  - Device name must be **trimmed** for trailing whitespace before parsing.

The client computes a CRC16 (same Modbus variant described later) over the meaningful prefix of this message and appends it before padding and encryption.

#### 6.3 Step 2: Cube Response (FE 26)

Example **decrypted** 48-byte Cube Hello:

```text
FE 26 02 0F C9 70 39 03 54 43 55 20 13 11 42 41
12 35 44 33 53 00 25 12 00 00 51 10 34 31 52 54
22 24 00 5E D2 27 00 00 00 00 00 00 00 00 00 00
```

Field breakdown:
- Bytes 0–1: `FE 26` – Cube Hello / state snapshot header
- Bytes 2–6: `02 0F C9 70 39` – **Session token** (5 bytes)
- Byte 7: `03` – Protocol version / flags
- **Bytes 8–20** – Cube state encoding (see section 7)
- Bytes 21–35 – Additional piece/state information and counters
- Bytes 36–37: `5E D2` – Possibly battery or status value
- Byte 38: `27` (decimal 39) – May correlate with move counter or internal index
- Remaining bytes: padding / reserved

The client must **copy the session token (bytes 2–6)** into the acknowledgment frame.

#### 6.4 Step 3: Client Acknowledgment (FE 09)

Example **decrypted** Client Ack:

```text
FE 09 02 0F C9 70 39 4B 6E 00 00 00 00 00 00 00
```

- Bytes 0–1: `FE 09` – Ack header
- Bytes 2–6: `02 0F C9 70 39` – Session token **copied from FE 26**
- Bytes 7–14: Application-specific data (often `4B 6E 00 00 00 00 00` in captures)
- Byte 15: Padding / reserved

The message is a **16-byte frame**, padded if needed, and then encrypted.

On the CubeZX side, the ack can be constructed as:
1. Start with `FE 09`.
2. Append bytes 2–6 from the decrypted `FE 26` message.
3. Optionally append additional fields.
4. Compute CRC16 over the first 14 bytes (see checksum section) and place the result in bytes 14–15.
5. Encrypt and send on FFF6.

**Important behavior:**
- The ack must be sent **once per connection**, when the first `FE 26` is processed.
- If the app never sends a valid `FE 09`, the cube continues to resend `FE 26`, even when idle.

#### 6.5 Step 4: Cube Ready (EE 10)

After receiving a correct ack, the cube sends an **initial EE 10 message** as a ready/initial state indicator.

Example:

```text
EE 10 00 C0 00 2E FF 00 00 00 FF 00 00 00 2D CD
```

- Bytes 0–1: `EE 10` – Move/state message (subtype 0x10)
- Bytes 2–13: Interpreted as a first window of state/moves (see move message format)
- Bytes 14–15: CRC16 checksum

After this, the cube starts sending regular `EE` (move/state) and `CC` (gyro) messages whenever the cube is manipulated.

---

### 7. Cube State Encoding in FE 26

The FE 26 message embeds a **full cube state snapshot** in bytes 8–20 and 21–35.

#### 7.1 Solved State Example

For a solved cube, the state bytes (7–35 region) look like:

```text
33 33 33 33 13 11 11 11 11 44 44 44 44 24 22 22 22 22 00 00 00 00 50 55 55 55 55 00 5A
```

Patterns:
- `33 33 33 33` + `13` – Corner group with zero orientation
- `11 11 11 11` – Edge group 1
- `44 44 44 44` + `24` – Corner group 2
- `22 22 22 22` – Edge group 2
- `00 00 00 00` – Padding or unused region
- `50 55 55 55 55` – Additional state/band data
- `5A` – Checksum or status byte

#### 7.2 Scrambled State Example

From one capture (scrambled cube):

```text
54 43 55 20 13 11 42 41 12 35 44 33 53 00 25 12 00 00 51 10 34 31 52 54 22 24 00 5E
```

The structure remains the same, but the repeated patterns are broken, reflecting piece permutations and orientations.

**Note:** The exact mapping from bytes to specific cubies and orientations is still under analysis. For most applications, the **incremental EE move messages** are sufficient to track state.

---

### 8. Move Messages (EE prefix)

After handshake, the cube sends **EE 10** messages for moves and some state updates.

#### 8.1 Frame Format

General format (decrypted, 16 bytes):

```text
EE 10 SS MM MM TT TT MM MM TT TT MM MM TT TT CC CC
```

Where:

| Offset | Size | Description                             |
|--------|------|-----------------------------------------|
| 0      | 1    | `EE` – Message type                     |
| 1      | 1    | `10` – Subtype                          |
| 2      | 1    | `SS` – Sequence number                  |
| 3–4    | 2    | Move 1 data (little-endian)             |
| 5–6    | 2    | Timestamp 1                             |
| 7–8    | 2    | Move 2 data                             |
| 9–10   | 2    | Timestamp 2                             |
| 11–12  | 2    | Move 3 data (if present)                |
| 13–14  | 2    | Timestamp 3 / CRC high byte (overlaps)  |
| 14–15  | 2    | `CC CC` – CRC16 (see section 10)        |

Example decoded frame:

```text
EE 10 01 50 01 3F 00 C0 00 2E FF 00 00 00 DB 97
       ^^ seq=1
          ^^^^^ move 1 data
                ^^^^^ timestamp 1
```

The cube often sends a **sliding window of recent moves (up to 5)**, but only the latest few may be present in any one frame.

#### 8.2 Move Encoding (upper nibble of move byte)

Each 16-bit move field (`MM MM`) is interpreted as follows:

```text
byte[3]     byte[4]
[MMTT]      [TTTT]
  ^           ^
  |           +-- Timestamp (lower 8 bits)
  +-- Upper nibble = Move type (0x1–0xC)
      Lower nibble = Timestamp (upper 4 bits)
```

- The **upper nibble of `byte[3]`** encodes the move type.
- Remaining bits form a **12-bit timestamp** (high 4 bits in `byte[3]` low nibble, low 8 bits in `byte[4]`).

Move type mapping (reference orientation after sync):

- Reference orientation:
  - **White** = Up (U)
  - **Green** = Front (F)
  - **Red** = Right (R)
  - **Yellow** = Down (D)
  - **Blue** = Back (B)
  - **Orange** = Left (L)

| Nibble | Move | Face / Direction                | Verified |
|--------|------|---------------------------------|----------|
| 0x1    | L'   | Left (orange) CCW              |          |
| 0x2    | L    | Left (orange) CW               | ✓        |
| 0x3    | R'   | Right (red) CCW                |          |
| 0x4    | R    | Right (red) CW                 | ✓        |
| 0x5    | D'   | Down (yellow) CCW              |          |
| 0x6    | D    | Down (yellow) CW               | ✓        |
| 0x7    | U'   | Up CCW                         | ✓        |
| 0x8    | U    | Up CW                          | ✓        |
| 0x9    | F'   | Front (green) CCW              |          |
| 0xA    | F    | Front (green) CW               | ✓        |
| 0xB    | B'   | Back CCW                       |          |
| 0xC    | B    | Back CW                        | ✓        |

**Verified from CubeZX testing:**
- All moves confirmed working with real Tornado V4 cube

#### 8.3 Example: Extracting Move and Timestamp

From the capture:

```text
byte[3] = 0xA0, byte[4] = 0x05
```

- `0xA0` binary: `1010 0000`
  - Upper nibble `1010` (`0xA`) → move type = **F** (Front CW)
  - Lower nibble `0000` → timestamp high bits = 0
- `byte[4] = 0x05` → timestamp low bits = 5

So this move is **F** at timestamp 5 (relative scale, not absolute time).

---

### 9. Gyroscope Messages (CC prefix)

The cube also sends **IMU / gyro messages** with prefix `CC 10`.

#### 9.1 Frame Format

Decrypted format:

```text
CC 10 SS GX GX 5E 02 GY GY GZ GZ ...
```

Where:

| Offset | Size | Description                          | Range                |
|--------|------|--------------------------------------|----------------------|
| 0      | 1    | `CC` – Message type                  |                      |
| 1      | 1    | `10` – Subtype                       |                      |
| 2      | 1    | `SS` – Sequence number               |                      |
| 3–4    | 2    | Gyro X (signed 16-bit, little-endian)| −32768 to 32767      |
| 5–6    | 2    | Constant `0x025E` (606 decimal)      | Fixed                |
| 7–8    | 2    | Gyro Y (signed 16-bit)               | −32768 to 32767      |
| 9–10   | 2    | Gyro Z (signed 16-bit)               | −32768 to 32767      |
| ...    | ...  | Additional sensor / padding          |                      |

#### 9.2 Example Readings

Sample decoded values:

```text
Gyro X: -2300, Y: -426, Z: -685
Gyro X: 27653, Y: -403, Z: -613
Gyro X: -7419, Y: -409, Z: -612
```

These values represent angular velocity or orientation in vendor-defined units. They can be used to track cube orientation or to implement motion-based gestures.

---

### 10. Checksum (CRC16)

All short (16-byte) `EE` and `CC` messages end with a **CRC-16 MODBUS** checksum in the last two bytes.

- **Algorithm**: CRC-16 Modbus
- **Polynomial**: 0x8005 (reflected: 0xA001)
- **Initial value**: 0xFFFF
- **Byte order**: Little-endian (low byte first)
- **Input for EE/CC frames**: bytes 0–13 (first 14 bytes of decrypted message)
- **Output**: bytes 14–15 of the decrypted frame

Reference Python implementation:

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

The same CRC variant is also used in handshake-related frames (`FE 15`, `FE 09`, etc.), computed over their unpadded payload bytes.

---

### 11. Advertising Data

#### 11.1 Manufacturer Specific Data (0xFF)

- **Company ID**: `0x0504`
- Payload includes:
  - Device MAC address
  - Status / flags bits (exact mapping not fully decoded)

#### 11.2 Scan Response

- **Complete Local Name**: `"XMD-TornadoV4-i-XXXX"`
- **Connection Interval Range**: `0x0010–0x0020`

These fields are standard BLE advertising structures and mainly used by the central for discovery and connection tuning.

---

### 12. References and Capture Files

The reverse engineering is based on the following files in the repository:

- Scrambled cube captures:
  - `contrib/data/XMD-Tornado-V4-i-0A87-raw.txt`
- BTSnoop logs:
  - `contrib/data/XMD-Tornado-V4-i-0A87-btsnoop.log`
  - `contrib/data/XMD-Tornado-V4-i-0A87-solved-btsnoop.log`
- Color-specific captures:
  - `contrib/data/XMD-Tornado-V4-i-0A87-green-yellow-orange-raw.txt`
  - `contrib/data/XMD-Tornado-V4-i-0A87-red-blue-raw.txt`
- Tools:
  - `contrib/decrypt_tornado.py` – AES decryption helper
  - `contrib/analyze_red.py` – analysis script for move patterns

Use these together with this document to validate behavior on firmware updates and to extend the protocol description (e.g., full cube-state mapping, extended commands).
