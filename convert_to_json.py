#!/usr/bin/env python3
import sys
if sys.argv.__len__() != 3:
    print("Invalid arguments. Expected <input_file> and <json_file> as arguments")
    exit(1)

import json

original_data = open(sys.argv[1], 'r').read()

res = {}
for line in original_data.split('\n'):
    if line == '': continue
    parts = line.split('=', 1)
    # print(parts)
    try:
        res[parts[0]] = int(parts[1])
    except ValueError:
        res[parts[0]] = parts[1]


print(f'Writing {res.keys().__len__()} entries to {sys.argv[2]}')
json.dump(res, open(sys.argv[2], 'w'), indent=4)