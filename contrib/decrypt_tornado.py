#!/usr/bin/env python3
"""
Decrypt XMD Tornado V4 BLE protocol data using known AES key.
Pure Python AES implementation (no external dependencies).
"""

# AES S-box
SBOX = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
]

# Inverse S-box for decryption
INV_SBOX = [
    0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
    0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
    0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
    0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
    0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
    0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
    0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
    0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
    0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
    0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
    0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
    0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
    0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
    0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
    0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
    0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d,
]

RCON = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36]

def xtime(a):
    return ((a << 1) ^ 0x1b) & 0xff if a & 0x80 else (a << 1) & 0xff

def multiply(a, b):
    result = 0
    for _ in range(8):
        if b & 1:
            result ^= a
        a = xtime(a)
        b >>= 1
    return result

def key_expansion(key):
    w = [list(key[i:i+4]) for i in range(0, 16, 4)]
    for i in range(4, 44):
        temp = w[i-1][:]
        if i % 4 == 0:
            temp = [SBOX[temp[1]], SBOX[temp[2]], SBOX[temp[3]], SBOX[temp[0]]]
            temp[0] ^= RCON[i//4 - 1]
        w.append([w[i-4][j] ^ temp[j] for j in range(4)])
    return w

def add_round_key(state, round_key):
    for i in range(4):
        for j in range(4):
            state[i][j] ^= round_key[j][i]

def inv_sub_bytes(state):
    for i in range(4):
        for j in range(4):
            state[i][j] = INV_SBOX[state[i][j]]

def inv_shift_rows(state):
    state[1] = state[1][3:] + state[1][:3]
    state[2] = state[2][2:] + state[2][:2]
    state[3] = state[3][1:] + state[3][:1]

def inv_mix_columns(state):
    for i in range(4):
        a = state[0][i]
        b = state[1][i]
        c = state[2][i]
        d = state[3][i]
        state[0][i] = multiply(a, 0x0e) ^ multiply(b, 0x0b) ^ multiply(c, 0x0d) ^ multiply(d, 0x09)
        state[1][i] = multiply(a, 0x09) ^ multiply(b, 0x0e) ^ multiply(c, 0x0b) ^ multiply(d, 0x0d)
        state[2][i] = multiply(a, 0x0d) ^ multiply(b, 0x09) ^ multiply(c, 0x0e) ^ multiply(d, 0x0b)
        state[3][i] = multiply(a, 0x0b) ^ multiply(b, 0x0d) ^ multiply(c, 0x09) ^ multiply(d, 0x0e)

def aes_decrypt_block(block, expanded_key):
    state = [[block[i + 4*j] for j in range(4)] for i in range(4)]
    add_round_key(state, expanded_key[40:44])
    for round in range(9, 0, -1):
        inv_shift_rows(state)
        inv_sub_bytes(state)
        add_round_key(state, expanded_key[round*4:(round+1)*4])
        inv_mix_columns(state)
    inv_shift_rows(state)
    inv_sub_bytes(state)
    add_round_key(state, expanded_key[0:4])
    return bytes([state[i][j] for j in range(4) for i in range(4)])

# Known AES-128 key
KEY = bytes([0x57, 0xb1, 0xf9, 0xab, 0xcd, 0x5a, 0xe8, 0xa7, 
             0x9c, 0xb9, 0x8c, 0xe7, 0x57, 0x8c, 0x51, 0x08])
EXPANDED_KEY = key_expansion(KEY)

def decrypt(data: bytes) -> bytes:
    """Decrypt AES-128 ECB data."""
    return aes_decrypt_block(data, EXPANDED_KEY)

def hex_to_bytes(hex_str: str) -> bytes:
    """Convert hex string to bytes."""
    return bytes.fromhex(hex_str.replace(' ', ''))

def print_hex(data: bytes, label: str = ""):
    """Print bytes as hex."""
    hex_str = ' '.join(f'{b:02X}' for b in data)
    if label:
        print(f"{label}: {hex_str}")
    else:
        print(hex_str)

# Sample encrypted data from capture
samples = {
    "handshake_1_send": "3C CD 26 49 2D 58 DC 2E C2 94 50 54 55 1B A8 DC 5B B6 C7 B2 A5 BD D5 36 23 85 BE 36 EC 03 B4 E7",
    "handshake_1_recv": "51 39 6A 7F 3A E2 EA 7D CF B4 15 3A A3 5E 09 C1 AC 9E D7 64 B2 F7 47 48 51 89 62 F6 B5 F5 8D 9C A5 33 7F 4E BD FB 50 BB 34 40 97 CB C6 C7 88 7F",
    "handshake_2_send": "63 59 A6 DE E8 A5 4A CD 3C 2D 53 FE 16 45 1D 3B",
    "handshake_2_recv": "8F 4C 21 A6 BD 74 7F 11 37 C7 7D AF 1B 68 AB 76",
    "move_1": "AA 13 43 DF 96 1F EC FD 57 59 61 76 B2 11 6C 92",
    "move_2": "96 EF 2A 8E F4 B6 D2 23 8A D9 42 2C 0D BB C5 0A",
    "move_3": "58 71 13 50 2A 1C F8 BD 18 02 5B 19 EE 14 A3 F6",
    "move_4": "02 06 1F 2C 43 76 5D 92 80 F9 5C 70 62 CD E6 17",
    "move_5": "35 34 05 68 14 42 9C 95 82 7F F3 67 9D 93 66 DF",
    "move_6": "36 6C CE 23 CA 20 1E AD 32 2A C6 28 FE 77 80 DB",
    "move_7": "3F 36 6D A6 E2 90 AD A2 26 AA 11 E0 62 38 49 7F",
    "move_8": "DC 06 2B 67 02 13 A2 81 D4 A1 DC A4 96 0B 6C 42",
    "move_9": "B3 51 6E B6 22 07 84 36 7A 1A 16 BD 58 DD 72 AD",
    "move_10": "34 9C 22 57 66 95 73 00 0A B4 D8 F0 74 4E F0 93",
    "move_11": "9C 2E 45 F0 76 52 29 95 CC C2 FC 74 D5 BE 2B 02",
    "move_12": "54 8A C2 BA D3 3B 9A 5E E2 D1 9D 82 D8 52 1A D2",
}

print("=" * 60)
print("XMD Tornado V4 Protocol Decryption")
print("=" * 60)
print(f"AES Key: {' '.join(f'{b:02X}' for b in KEY)}")
print("=" * 60)

# ============================================================
# SOLVED CUBE CAPTURE ANALYSIS
# ============================================================
print("\n" + "=" * 60)
print("SOLVED CUBE CAPTURE ANALYSIS")
print("Sequence: U U' D D' F F' B B' R R' L L'")
print("=" * 60)

# Handshake response from solved cube (frame 645)
solved_handshake = hex_to_bytes("40 3b d6 63 fc bd e0 b1 92 1a 43 f4 49 1f 56 3a 9c cd 2f 40 2f a4 6b 8a 7a dc 08 70 fe 25 1d fb 0a f3 ee a5 82 09 f4 3a ba e4 20 6a 10 b6 32 a3")
print(f"\nHandshake response (48 bytes):")
decrypted_hs = b''
for i in range(0, len(solved_handshake), 16):
    block = solved_handshake[i:i+16]
    if len(block) == 16:
        decrypted_hs += decrypt(block)
print(f"  Decrypted: {' '.join(f'{b:02X}' for b in decrypted_hs)}")
print(f"  ASCII:     {''.join(chr(b) if 32 <= b < 127 else '.' for b in decrypted_hs)}")

# Compare with scrambled cube handshake
print(f"\nSOLVED state bytes (8-35):")
for i in range(8, min(36, len(decrypted_hs))):
    b = decrypted_hs[i]
    print(f"  [{i:2d}]: 0x{b:02X} = {b:3d} = '{chr(b) if 32 <= b < 127 else '?'}'")

# Move messages from solved cube capture - need to find EE messages
# Sequence was: U U' D D' F F' B B' R R' L L'
solved_moves = [
    ("frame_656", "d2 d5 02 f4 05 1f e2 36 c5 4f d7 cd 93 57 d6 be"),
    ("frame_657", "57 a9 01 50 9a bf 66 5e e7 87 5a 3a 94 9b 44 03"),
    ("frame_679", "58 86 d4 aa 76 da 45 d8 6b c8 9f ad c6 fb 64 95"),
    ("frame_680", "6e 34 9b e5 4e 4c 0b df ec d0 8b c7 81 83 4b d0"),
    ("frame_681", "df f8 83 29 94 5b 80 0b 10 0d 62 b8 2e f9 5c 09"),
    ("frame_686", "34 a0 de bf 7a bc 2d ed f7 61 97 2a 2e 60 88 88"),
    ("frame_687", "89 bc ee 68 65 6f f9 89 ec d5 a1 76 f7 be 72 12"),
    ("frame_688", "19 e4 71 e5 07 7e 3f d2 a8 f7 fe 9d e9 47 ea 2d"),
    ("frame_689", "34 58 9b e8 80 d7 bd 04 9d 57 91 fe a4 9c c5 26"),
    ("frame_690", "76 04 46 fa 61 e1 eb fa db d4 18 00 88 e1 53 c9"),
    ("frame_694", "36 47 32 19 5a 56 b6 fb bd 44 ba ea 6d ab 21 de"),
    ("frame_695", "2a 3d a6 63 10 0f 66 bf 9b 2f 82 64 56 95 f6 6a"),
    ("frame_696", "3a 9c e6 66 7b 7e 84 16 54 69 68 b4 50 67 20 85"),
    ("frame_697", "85 9e eb c5 a5 c8 aa 5b 74 3f 9d a8 a8 9f 4f e4"),
    ("frame_698", "ef 5f 52 7e ec 6e 9c ae b8 c5 6b d3 68 e8 03 91"),
    ("frame_699", "97 74 93 ad db 87 a6 4b 8a 06 a4 19 74 f3 25 47"),
    ("frame_700", "a0 e9 0c b4 99 e2 10 4a 89 e5 95 54 b7 e8 68 0e"),
    ("frame_701", "a7 62 63 a8 77 82 3e 97 b8 fc 46 cc 08 d9 84 fc"),
    ("frame_705", "13 d7 49 81 b0 5a 29 a0 73 ce e0 aa 2a 89 78 2c"),
    ("frame_706", "31 ff f4 3e f9 0c 20 d7 11 37 3b c8 7b 79 d0 79"),
]

# All packets from solved cube capture - find EE messages
all_packets = [
    "d2d502f4051fe236c54fd7cd9357d6be", "57a901509abf665ee7875a3a949b4403",
    "7cf1cb4743532358e4e18cb4cfb0656c", "3bef856f9a2cb454595aee223543041c",
    "d9e490c933368ebeb3b08266cc60201e", "e555323e7020c94224bbede93cdbbcb3",
    "1e2e4a92d31419fe8a47cd8a6eddfe8c", "d7b167cef5b9355e75f6880e518edcf9",
    "e558fd5c9e2ccd5ba79ddb03821bacb2", "021594bb94723991c015b4583a26fe59",
    "0b959029efa2991b5286e726448261fa", "5e70b9bce48d592dba417b82bc670822",
    "5886d4aa76da45d86bc89fadc6fb6495", "6e349be54e4c0bdfecd08bc781834bd0",
    "dff88329945b800b100d62b82ef95c09", "5dcaccce67a88420a9a795e69311c188",
    "34a0debf7abc2dedf761972a2e608888", "89bcee68656ff989ecd5a176f7be7212",
    "19e471e5077e3fd2a8f7fe9de947ea2d", "34589be880d7bd049d5791fea49cc526",
    "760446fa61e1ebfadbd4180088e153c9", "c5cdccc3c4ec51dc7a2f71733047e4f8",
    "364732195a56b6fbbd44baea6dab21de", "2a3da663100f66bf9b2f82645695f66a",
    "3a9ce6667b7e8416546968b450672085", "859eebc5a5c8aa5b743f9da8a89f4fe4",
    "ef5f527eec6e9caeb8c56bd368e80391", "977493addb87a64b8a06a41974f32547",
    "a0e90cb499e2104a89e59554b7e8680e", "a76263a877823e97b8fc46cc08d984fc",
    "13d74981b05a29a073cee0aa2a89782c", "31fff43ef90c20d711373bc87b79d079",
    "bb2f6f8ae8a28805a9fe62decf377324", "637b9b0119795c3a0d967cb665b324c6",
    "cbb774aa76058e7ba642cc2b965ead57", "4b2abffa9099f0bc2d0000f3619c9cef",
    "92fffbe9faa5496eb5a8aaa40e7c4411", "85bb563ef2926620ef81e395768ddfc0",
    "b4da391868d3ca683558a4e85147b97f", "0e80571206b73da18e7fc5cd077dd967",
    "e73b17622a0b5ee5fdefc02cc6b971ea", "d4e9fb18ee484889584dbd5be6d8e335",
    "d61e007792a21fa76fdea314c5492b75", "48059d7900689a0feae7dc6b086e51fc",
    "909ead4f983ae7033d392ebf36964049", "d58d7d089a289d4b35296f17066395c1",
    "3838f14eaa00f1522b40245f90d9857f", "a0ed58cc0ae17745490005545a82308e",
]

print("\n" + "-" * 60)
print("SEARCHING FOR EE (MOVE) MESSAGES:")
print("Expected sequence: U U' D D' F F' B B' R R' L L'")
print("-" * 60)

ee_count = 0
for i, hex_data in enumerate(all_packets):
    encrypted = bytes.fromhex(hex_data)
    decrypted = decrypt(encrypted)
    
    if decrypted[0] == 0xEE:
        ee_count += 1
        print(f"\nPacket {i}: EE message found!")
        print(f"  Decrypted: {' '.join(f'{b:02X}' for b in decrypted)}")
        moves = []
        for j in range(3, 13, 2):
            move_byte = decrypted[j] & 0x0F
            if move_byte in MOVE_TABLE:
                moves.append(MOVE_TABLE[move_byte])
        if moves:
            print(f"  Moves (newest first): {' '.join(moves)}")
            print(f"  Sequence: {' '.join(reversed(moves))}")

print(f"\nTotal EE messages found: {ee_count}")

print("\n" + "=" * 60)

# Analyze handshake response cube state
print("\n=== CUBE STATE ANALYSIS ===")
handshake_resp = hex_to_bytes("51 39 6A 7F 3A E2 EA 7D CF B4 15 3A A3 5E 09 C1 AC 9E D7 64 B2 F7 47 48 51 89 62 F6 B5 F5 8D 9C A5 33 7F 4E BD FB 50 BB 34 40 97 CB C6 C7 88 7F")
decrypted_state = b''
for i in range(0, len(handshake_resp), 16):
    block = handshake_resp[i:i+16]
    if len(block) == 16:
        decrypted_state += decrypt(block)

print(f"Decrypted: {' '.join(f'{b:02X}' for b in decrypted_state)}")
print(f"ASCII:     {''.join(chr(b) if 32 <= b < 127 else '.' for b in decrypted_state)}")

# Bytes 8-20 seem to contain cube state
state_bytes = decrypted_state[8:21]
print(f"\nState bytes (8-20): {' '.join(f'{b:02X}' for b in state_bytes)}")
print(f"As ASCII: {''.join(chr(b) if 32 <= b < 127 else '.' for b in state_bytes)}")

# Try to interpret as facelet positions
# Standard cube has 54 facelets (9 per face x 6 faces)
# But we only have ~13 bytes here, so maybe it's compressed or different encoding
print(f"\nPossible facelet encoding:")
for i, b in enumerate(state_bytes):
    if b != 0:
        print(f"  [{i:2d}]: 0x{b:02X} = {b:3d} = '{chr(b) if 32 <= b < 127 else '?'}'")

print("=" * 60)

for name, hex_data in samples.items():
    encrypted = hex_to_bytes(hex_data)
    print(f"\n{name} ({len(encrypted)} bytes):")
    print(f"  Encrypted: {' '.join(f'{b:02X}' for b in encrypted[:16])}...")
    
    # Decrypt each 16-byte block
    decrypted = b''
    for i in range(0, len(encrypted), 16):
        block = encrypted[i:i+16]
        if len(block) == 16:
            decrypted += decrypt(block)
    
    print(f"  Decrypted: {' '.join(f'{b:02X}' for b in decrypted)}")
    
    # Try to interpret as ASCII where possible
    ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in decrypted)
    print(f"  ASCII:     {ascii_str}")
    
    # Move encoding table
    MOVE_TABLE = {
        0x1: "L'", 0x2: "L", 0x3: "R'", 0x4: "R",
        0x5: "D'", 0x6: "D", 0x7: "U'", 0x8: "U",
        0x9: "F'", 0xA: "F", 0xB: "B'", 0xC: "B",
    }
    
    # Analyze message type
    if decrypted[0] == 0xEE:
        print(f"  Type: MOVE - seq={decrypted[2]}")
        # Parse move data - format: [move_low][ts_high] as 16-bit LE
        # Move is in FIRST byte (lower byte), lower nibble
        moves = []
        for i in range(3, 13, 2):
            move_byte = decrypted[i] & 0x0F  # First byte, lower nibble = move
            ts = (decrypted[i] >> 4) | (decrypted[i+1] << 4)  # Upper 12 bits = timestamp
            if move_byte in MOVE_TABLE:
                move_name = MOVE_TABLE[move_byte]
                moves.append(move_name)
                print(f"    move=0x{move_byte:X} ({move_name:2s}), ts={ts:4d}")
            elif move_byte == 0 and decrypted[i] == 0 and decrypted[i+1] == 0:
                pass  # Empty slot
            else:
                print(f"    raw=0x{decrypted[i]:02X}{decrypted[i+1]:02X} -> move=0x{move_byte:X} (?)")
        if moves:
            print(f"  Sequence: {' '.join(reversed(moves))}")
    elif decrypted[0] == 0xCC:
        print(f"  Type: GYRO - seq={decrypted[2]}")
        # Parse gyro data as signed 16-bit
        gx = decrypted[3] | (decrypted[4] << 8)
        if gx > 32767: gx -= 65536
        gy = decrypted[7] | (decrypted[8] << 8)
        if gy > 32767: gy -= 65536
        gz = decrypted[9] | (decrypted[10] << 8)
        if gz > 32767: gz -= 65536
        print(f"    Gyro X: {gx}, Y: {gy}, Z: {gz}")
