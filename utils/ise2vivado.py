#!/usr/bin/env python3

import xml.etree.ElementTree as ET
import sys
from pathlib import Path

tree = ET.parse(sys.argv[1])
root = tree.getroot()

# print(root.tag)
# print(root.text)
# print(root.attrib)
# print(root[2].tag)

ns = {"x": "http://www.xilinx.com/XMLSchema"}

f = dict()
f_types = ["FILE_VHDL", "FILE_VERILOG"]

for files in root.findall('x:files', ns):
    for file in files.findall('x:file', ns):
        namespace = f"{{{ns['x']}}}"
        name = file.get(namespace+'name')
        type = file.get(namespace+'type')
        if type in f_types:
            if type not in f.keys():
                f[type] = []
            f[type].append(name)
        else:
            print(f"unexpected file type: {type}")


template = """\
CAPI=2:
name: 
description:

filesets:
  rtl:
    files:
{}

targets:
  default: &default
    filesets:
      - rtl
    toplevel: 

"""

output = dict()
for type in f_types:
    for file in f[type]:
        if 'ip_cores' not in file:
            if '../../' in file:
                p = Path(file.replace('../../', ''))
                if p.parent not in output.keys():
                    output[p.parent] = []
                output[p.parent].append(p.name)

for k,v in output.items():
    p = Path(k)
    with (p / p.name).with_suffix('.core').open('w') as f:
        text = ['      - '+x for x in v]
        f.write(template.format('\n'.join(text)))