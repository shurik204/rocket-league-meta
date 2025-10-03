#!/usr/bin/env python3
import sys
if sys.argv.__len__() != 2:
    print("Invalid arguments. Expected GPsyonixBuildID as the only argument")
    exit(1)

import numpy as np

nonce = np.frombuffer(open('PsyBuildIdNonce', 'rb').read(), dtype=np.uint32)

def calculate(gPsyonixBuildId: str) -> int:
    result = np.uint32(np.iinfo(np.uint32).max)
    for i, char in enumerate(gPsyonixBuildId):
        chr = ord(char)
        # result = result << 8 ^ Nonce[(byte)(((result >> 24) ^ chr) & 0xFF)];
        result = np.bitwise_xor(np.bitwise_left_shift(result, 8), nonce[int(np.bitwise_xor(np.bitwise_right_shift(result, 24), chr) & 0xFF)])
        # result = result << 8 ^ Nonce[(byte)(result >> 24 ^ (chr >> 8))];
        result = np.bitwise_xor(np.bitwise_left_shift(result, 8), nonce[int(np.bitwise_xor(np.bitwise_right_shift(result, 24), np.bitwise_right_shift(chr, 8)))])
    return int(np.int32(np.bitwise_invert(result)))

print(calculate(sys.argv[1]), end='')