#!/usr/bin/env python3
"""
Tornado V4 BLE Capture Decoder

Decodes encrypted FFF6 messages from Bluetooth HCI captures.
Uses AES-128 ECB as specified in tornado-v4-protocol.md
"""

import sys
import re

# Try different crypto libraries
try:
    from Crypto.Cipher import AES
    def aes_decrypt(data: bytes, key: bytes) -> bytes:
        cipher = AES.new(key, AES.MODE_ECB)
        return cipher.decrypt(data)
except ImportError:
    try:
        from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
        from cryptography.hazmat.backends import default_backend
        def aes_decrypt(data: bytes, key: bytes) -> bytes:
            cipher = Cipher(algorithms.AES(key), modes.ECB(), backend=default_backend())
            decryptor = cipher.decryptor()
            return decryptor.update(data) + decryptor.finalize()
    except ImportError:
        # Pure Python AES implementation (minimal, for fallback)
        print("Warning: No crypto library found. Install pycryptodome or cryptography.")
        print("pip install pycryptodome")
        sys.exit(1)

# AES keys from protocol spec
KEYS = {
    'default': bytes.fromhex('57B1F9ABCD5AE8A79CB98CE7578C5108'),
    'alt': bytes.fromhex('11223344556677889900aabbccddeeff'),
    '5HH': bytes.fromhex('11041989aefce0385f11041989aefce0385f')[:16],
}

# Message type descriptions
MSG_TYPES = {
    0xFE: 'Handshake',
    0xEE: 'Move Data',
    0xDD: 'Move Marker',
    0xCC: 'Gyroscope',
}

MOVE_NAMES = {
    0x0: '-',
    0x1: "L'", 0x2: 'L',
    0x3: "R'", 0x4: 'R',
    0x5: "D'", 0x6: 'D',
    0x7: "U'", 0x8: 'U',
    0x9: "F'", 0xA: 'F',
    0xB: "B'", 0xC: 'B',
}

FACE_COLORS = ['Orange(L)', 'Red(R)', 'Yellow(D)', 'White(U)', 'Green(F)', 'Blue(B)']


def decrypt_block(data: bytes, key: bytes) -> bytes:
    """Decrypt a single 16-byte AES block"""
    return aes_decrypt(data, key)


def decrypt_message(data: bytes, key: bytes) -> bytes:
    """Decrypt multi-block message (each 16 bytes independently)"""
    result = bytearray()
    for i in range(0, len(data), 16):
        block = data[i:i+16]
        if len(block) == 16:
            result.extend(decrypt_block(block, key))
    return bytes(result)


def crc16_modbus(data: bytes) -> int:
    """Calculate CRC-16 MODBUS checksum"""
    crc = 0xFFFF
    for byte in data:
        crc ^= byte
        for _ in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ 0xA001
            else:
                crc >>= 1
    return crc


def parse_fe_message(data: bytes) -> dict:
    """Parse FE (Handshake) message"""
    result = {'type': 'FE', 'subtype': data[1]}
    
    if data[1] == 0x15:
        # Client Hello
        result['name'] = 'Client Hello'
        result['client_id'] = data[2:7].hex()
        result['mac'] = ':'.join(f'{b:02X}' for b in reversed(data[13:19]))
    elif data[1] == 0x26:
        # Handshake Response or Set State
        flag = data[2]
        if flag == 0x02:
            result['name'] = 'Handshake Response'
        elif flag == 0x04:
            result['name'] = 'Set State Command/Response'
        else:
            result['name'] = f'FE 26 (flag={flag:02X})'
        result['session'] = data[3:7].hex()
        # Facelets are in bytes 7-33 (27 bytes = 54 nibbles)
        if len(data) >= 34:
            facelets = []
            for i in range(7, 34):
                facelets.append((data[i] >> 4) & 0x0F)
                facelets.append(data[i] & 0x0F)
            result['facelets'] = facelets[:54]
        if len(data) >= 36:
            result['battery'] = data[35]
    elif data[1] == 0x09:
        result['name'] = 'Client ACK'
        result['session'] = data[2:7].hex()
    
    return result


def parse_ee_message(data: bytes) -> dict:
    """Parse EE (Move Data) message"""
    result = {'type': 'EE', 'subtype': data[1], 'name': 'Move Data'}
    result['seq'] = data[2]
    
    # 3 move slots
    slots = []
    for i, offset in enumerate([3, 7, 11]):
        if offset < len(data):
            move_byte = data[offset]
            move = MOVE_NAMES.get(move_byte & 0x0F, f'?{move_byte:02X}')
            timestamp = int.from_bytes(data[offset+1:offset+3], 'little') if offset+2 < len(data) else 0
            slots.append({'move': move, 'byte': move_byte, 'ts': timestamp})
    result['slots'] = slots
    
    return result


def parse_dd_message(data: bytes) -> dict:
    """Parse DD (Move Marker) message"""
    result = {'type': 'DD', 'subtype': data[1]}
    
    if data[1] == 0x10:
        result['name'] = 'Move Marker'
        result['seq'] = data[2]
        # Similar structure to EE
        slots = []
        for i, offset in enumerate([3, 7, 11]):
            if offset < len(data):
                move_byte = data[offset]
                move = MOVE_NAMES.get(move_byte & 0x0F, f'?{move_byte:02X}')
                slots.append({'move': move, 'byte': move_byte})
        result['slots'] = slots
    elif data[1] == 0x09:
        result['name'] = 'Move ACK'
        result['seq'] = data[2]
    
    return result


def parse_cc_message(data: bytes) -> dict:
    """Parse CC (Gyroscope) message"""
    result = {'type': 'CC', 'subtype': data[1], 'name': 'Gyroscope'}
    result['seq'] = data[2]
    result['timestamp'] = int.from_bytes(data[3:5], 'little')
    
    # Quaternion: big-endian signed 16-bit, scaled by 1000
    if len(data) >= 14:
        qw = int.from_bytes(data[6:8], 'big', signed=True) / 1000.0
        qx = int.from_bytes(data[8:10], 'big', signed=True) / 1000.0
        qy = int.from_bytes(data[10:12], 'big', signed=True) / 1000.0
        qz = int.from_bytes(data[12:14], 'big', signed=True) / 1000.0
        result['quaternion'] = {'w': qw, 'x': qx, 'y': qy, 'z': qz}
    
    return result


def parse_message(data: bytes) -> dict:
    """Parse decrypted message based on prefix byte"""
    if not data:
        return {'type': 'empty'}
    
    prefix = data[0]
    
    if prefix == 0xFE:
        return parse_fe_message(data)
    elif prefix == 0xEE:
        return parse_ee_message(data)
    elif prefix == 0xDD:
        return parse_dd_message(data)
    elif prefix == 0xCC:
        return parse_cc_message(data)
    else:
        return {'type': 'unknown', 'prefix': f'{prefix:02X}'}


def format_parsed(parsed: dict) -> str:
    """Format parsed message for display"""
    msg_type = parsed.get('type', '?')
    name = parsed.get('name', msg_type)
    
    parts = [f"[{name}]"]
    
    if 'seq' in parsed:
        parts.append(f"seq={parsed['seq']}")
    
    if 'slots' in parsed:
        moves = ' '.join(s['move'] for s in parsed['slots'] if s['move'] != '-')
        if moves:
            parts.append(f"moves: {moves}")
    
    if 'quaternion' in parsed:
        q = parsed['quaternion']
        parts.append(f"quat: w={q['w']:.3f} x={q['x']:.3f} y={q['y']:.3f} z={q['z']:.3f}")
    
    if 'battery' in parsed:
        parts.append(f"battery={parsed['battery']}%")
    
    if 'session' in parsed:
        parts.append(f"session={parsed['session']}")
    
    if 'mac' in parsed:
        parts.append(f"MAC={parsed['mac']}")
    
    return ' '.join(parts)


def extract_hex_from_line(line: str) -> bytes | None:
    """Extract hex payload from HCI capture line"""
    # Pattern: look for hex bytes at end of line after description
    # Example: "ATT Send ... Write Command - Handle:0x001A - FFF6 - Value: BABC 309A..."
    # Or raw hex: "42 00 27 00 23 00 04 00 52 1A 00 BA BC 30..."
    
    # Try to find Value: pattern
    value_match = re.search(r'Value:\s*([0-9A-Fa-f\s]+)$', line)
    if value_match:
        hex_str = value_match.group(1).replace(' ', '')
        try:
            return bytes.fromhex(hex_str)
        except:
            pass
    
    # Try to find raw hex at end (after all the description text)
    # Look for pattern like "52 1A 00 BA BC 30 9A..."
    hex_match = re.search(r'\s\s([0-9A-Fa-f]{2}(?:\s[0-9A-Fa-f]{2})+)\s*$', line)
    if hex_match:
        hex_str = hex_match.group(1).replace(' ', '')
        try:
            data = bytes.fromhex(hex_str)
            # ATT packet: skip first 7 bytes (HCI + L2CAP + ATT headers) for payload
            # Write Command: opcode 0x52, handle 2 bytes = 3 byte ATT header
            # But raw line includes more... let's find FFF6 data
            # Actually the whole line has HCI header, find start of payload
            if len(data) > 10:
                # Look for payload after ATT header
                # ATT Write Command: 52 [handle_lo] [handle_hi] [payload...]
                for i in range(len(data) - 3):
                    if data[i] == 0x52 and data[i+1] == 0x1A and data[i+2] == 0x00:
                        # Found Write Command to handle 0x001A
                        return data[i+3:]
                    if data[i] == 0x1B and data[i+1] == 0x1A and data[i+2] == 0x00:
                        # Found Notification from handle 0x001A
                        return data[i+3:]
            return data
        except:
            pass
    
    return None


def process_capture_file(filename: str, key: bytes, show_all: bool = False):
    """Process HCI capture file and decode messages"""
    print(f"Processing: {filename}")
    print(f"Using key: {key.hex()}")
    print("-" * 80)
    
    with open(filename, 'r') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            
            # Filter for FFF6 related lines
            if 'FFF6' not in line and '0x001A' not in line:
                continue
            
            # Determine direction
            if 'ATT Send' in line or 'Write Command' in line or 'Write Request' in line:
                direction = 'TX'
            elif 'ATT Receive' in line or 'Notification' in line:
                direction = 'RX'
            else:
                direction = '??'
            
            # Extract timestamp
            time_match = re.match(r'(\w+\s+\d+\s+[\d:\.]+)', line)
            timestamp = time_match.group(1) if time_match else ''
            
            # Extract hex data
            hex_data = extract_hex_from_line(line)
            if not hex_data or len(hex_data) < 16:
                continue
            
            # Decrypt
            decrypted = decrypt_message(hex_data, key)
            
            # Parse
            parsed = parse_message(decrypted)
            
            # Skip gyro messages unless show_all
            if not show_all and parsed.get('type') == 'CC':
                continue
            
            # Format output
            enc_hex = hex_data[:16].hex().upper()
            dec_hex = decrypted[:16].hex().upper()
            formatted = format_parsed(parsed)
            
            print(f"{timestamp} [{direction}] {formatted}")
            if show_all:
                print(f"    ENC: {enc_hex}")
                print(f"    DEC: {dec_hex}")


def decode_hex(hex_str: str, key: bytes):
    """Decode a single hex string"""
    hex_str = hex_str.replace(' ', '').replace(':', '')
    data = bytes.fromhex(hex_str)
    
    print(f"Input ({len(data)} bytes): {data.hex().upper()}")
    
    decrypted = decrypt_message(data, key)
    print(f"Decrypted: {decrypted.hex().upper()}")
    
    # Verify CRC
    if len(decrypted) >= 16:
        calc_crc = crc16_modbus(decrypted[:14])
        msg_crc = int.from_bytes(decrypted[14:16], 'little')
        crc_ok = "✓" if calc_crc == msg_crc else f"✗ (expected {calc_crc:04X})"
        print(f"CRC: {msg_crc:04X} {crc_ok}")
    
    parsed = parse_message(decrypted)
    print(f"Parsed: {format_parsed(parsed)}")
    print(f"Details: {parsed}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Decode Tornado V4 BLE messages')
    parser.add_argument('input', help='Capture file or hex string to decode')
    parser.add_argument('-k', '--key', choices=['default', 'alt', '5HH'], default='default',
                        help='AES key to use (default: default)')
    parser.add_argument('-x', '--hex', action='store_true',
                        help='Input is raw hex string instead of file')
    parser.add_argument('-a', '--all', action='store_true',
                        help='Show all messages including gyroscope')
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='Show encrypted/decrypted hex')
    
    args = parser.parse_args()
    key = KEYS[args.key]
    
    if args.hex:
        decode_hex(args.input, key)
    else:
        process_capture_file(args.input, key, show_all=args.all or args.verbose)


if __name__ == '__main__':
    main()
