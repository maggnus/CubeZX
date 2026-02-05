#!/usr/bin/env python3
from itertools import permutations

# Input 27 bytes from log (hex)
hex_bytes = "35 00 33 33 02 35 10 24 15 04 24 44 02 40 55 23 51 31 22 50 40 13 51 14 51 42 12"
facelet_bytes = bytes(int(x,16) for x in hex_bytes.split())
assert len(facelet_bytes) == 27

# protocol nibble -> color name mapping as in adapter
protocol_nibble_to_color = {
    0: 'orange',
    1: 'red',
    2: 'yellow',
    3: 'white',
    4: 'green',
    5: 'blue'
}

# target centers in our internal order U,D,L,R,F,B
target_centers = ['white','yellow','orange','red','green','blue']

# helper to unpack nibbles
def unpack(facelet_bytes, low_even):
    prot = []
    for i in range(54):
        byte_index = i//2
        if low_even:
            shift = (i%2)*4
        else:
            shift = (1-(i%2))*4
        nibble = (facelet_bytes[byte_index] >> shift) & 0x0F
        prot.append(nibble)
    return prot

# Try both unpack modes
solutions = []
for low_even in [True, False]:
    proto = unpack(facelet_bytes, low_even)
    # proto faces: assumed order in packet per-face: URFDLB (0..5)
    # For each permutation mapping protoFace -> ourFace
    for perm in permutations(range(6)):
        # compute centers
        centers = [None]*6
        for proto_face in range(6):
            center_nibble = proto[proto_face*9 + 4]
            centers[perm[proto_face]] = protocol_nibble_to_color.get(center_nibble, f'#{center_nibble}')
        if centers == target_centers:
            solutions.append((low_even, perm, centers))

# Report
if not solutions:
    print('No center-matching permutation found')
else:
    print('Found solutions:')
    for low_even, perm, centers in solutions:
        print('low_even=', low_even)
        print('perm proto->our =', perm)
        print('centers =', centers)
        print('---')

# If found, also produce protocolFaceToOurIndex array format
if solutions:
    low_even, perm, centers = solutions[0]
    mapping = list(perm)
    print('\nSuggested protocolFaceToOurIndex:')
    print(mapping)
    print('\nNibble unpacking: low_even =', low_even)
