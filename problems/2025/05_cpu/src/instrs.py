import re
import argparse
import yaml

SRC_FILE = "instrs.yaml"
DST_FILE = "instrs.mac.vh"

disclaimer = f"""
///////////////////////////////////////////////////////////////////////////////
//
// WARNING: This file is GENERATED from {SRC_FILE}.
//
// !!! DO NOT EDIT IT !!!
//
///////////////////////////////////////////////////////////////////////////////

"""
with open("instrs.yaml") as stream:
    try:
        lines = yaml.safe_load(stream)
    except yaml.YAMLError as exc:
        print(exc)

print(f"Preprocessing {len(lines)} instrs")
with open("instrs.mac.vh", "w") as file:
    file.write(disclaimer)

    keys = ['oper', 'enc', 'aluop', 'alu1', 'alu2', 'wbsel', 'wb_en', 'cmpop', 'is_branch', 'is_jump', 'is_store', 'store_mask']
    aluop = ["ADD", "SUB", "SLL", "SLT", "SLTU", "XOR", "SRL", "SRA", "OR", "AND", "X"]
    alu1  = ["UIMM", "BIMM", "JIMM", "REG1", "X"]
    alu2  = ["REG2", "IIMM", "SIMM", "PC", "X"]
    wbsel = ["UIMM", "ALURES", "LSU", "PC_INC", "X"]
    cmpop = ["BEQ", "BNE", "BLT", "BGE", "BLTU", "BGEU", "X"]

    unique_enc = {}

    for n, line in enumerate(lines):
        fail = False
        out = r"`OP("
        d = dict(zip(keys, line))

        m = re.match(r'\w*', d['oper'])
        if not m:
            print(f"{n}: Wrong oper format: {d['oper']}")
            fail = True
        out += f"{d['oper']:>4}, "

        m = re.match(r'[01?]{5}_[01?]{2}_[01?]{3}_[01?]{7}', d['enc'])
        if not m:
            print(f"{n}: Wrong encoding format: {d['enc']}")
            fail = True
        if d['enc'] in unique_enc:
            print(f"{n}: Encoding collision with instr {unique_enc[d['enc']]}: {d['enc']}")
            fail = True
        unique_enc[d['enc']] = n
        out += f"17'b{d['enc']}, "

        if d['aluop'] not in aluop:
            print(f"{n}: Wrong aluop format: {d['aluop']}")
            fail = True
        out += f"`ALUOP_{d['aluop']}, "

        if d['alu1'] not in alu1:
            print(f"{n}: Wrong alu1 format: {d['alu1']}")
            fail = True
        out += f"`ALUSEL1_{d['alu1']}, "

        if d['alu2'] not in alu2:
            print(f"{n}: Wrong alu2 format: {d['alu2']}")
            fail = True
        out += f"`ALUSEL2_{d['alu2']}, "

        if d['wbsel'] not in wbsel:
            print(f"{n}: Wrong wbsel format: {d['wbsel']}")
            fail = True
        out += f"`WBSEL_{d['wbsel']}, "

        m = re.match(r'[01]', str(d['wb_en']))
        if not m:
            print(f"{n}: Wrong wb_en format: {d['wb_en']}")
            fail = True
        out += f"1'b{d['wb_en']}, "

        if d['cmpop'] not in cmpop:
            print(f"{n}: Wrong cmpop format: {d['cmpop']}")
            fail = True
        out += f"`CMPOP_{d['cmpop']}, "

        m = re.match(r'[01]', str(d['is_branch']))
        if not m:
            print(f"{n}: Wrong is_branch format: {d['is_branch']}")
            fail = True
        out += f"1'b{d['is_branch']}, "

        m = re.match(r'[01]', str(d['is_jump']))
        if not m:
            print(f"{n}: Wrong is_jump format: {d['is_jump']}")
            fail = True
        out += f"1'b{d['is_jump']}, "

        m = re.match(r'[01]', str(d['is_store']))
        if not m:
            print(f"{n}: Wrong is_store format: {d['is_store']}")
            fail = True
        out += f"1'b{d['is_store']}, "

        m = re.match(r'[01]{4}', d['store_mask'])
        if not m:
            print(f"{n}: Wrong store_mask format: {d['store_mask']}")
            fail = True
        out += f"4'b{d['store_mask']}, "

        if fail:
            print(f"=== Failed on instr {n} ===")
            exit(1)

        out = out[:-2]
        out += ")\n"
        file.write(out)

    file.write(disclaimer)

print(f"Preprocessing successful")
