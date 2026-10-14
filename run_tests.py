#!/usr/bin/env python3
import os
import subprocess
import glob
import re

RTL_FILES = [
    "rtl/pc_reg.v", "rtl/adder.v", "rtl/imem.v", "rtl/control_unit.v", 
    "rtl/alu_decoder.v", "rtl/imm_gen.v", "rtl/regfile.v", "rtl/mux2.v", 
    "rtl/mux4.v", "rtl/alu.v", "rtl/branch_unit.v", "rtl/lsu.v", 
    "rtl/dmem.v", "rtl/next_pc.v", "rtl/top.v"
]
TB_FILE = "tb/tb_top.v"
SIM_EXEC = "sim_top"

def parse_simulation_output(output):
    sim_data = {}
    for line in output.splitlines():
        if "Final PC:" in line:
            match = re.search(r"0x[0-9a-fA-F]+", line)
            if match:
                sim_data["pc"] = match.group(0).lower()
        
        reg_matches = re.findall(r"(x\d+)\s*(?:\([^)]+\))?\s*=\s*(0x[0-9a-fA-F]+)", line)
        for reg, val in reg_matches:
            sim_data[reg.lower()] = val.lower()
    return sim_data

def parse_expect_file(expect_path):
    expect_data = {}
    if not os.path.exists(expect_path):
        return expect_data
        
    with open(expect_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            
            # Match format: R <reg_num> <hex_value> (e.g., R  1 0000000f)
            r_match = re.search(r"^R\s+(\d+)\s+([0-9a-fA-F]+)", line, re.IGNORECASE)
            if r_match:
                reg_num, val = r_match.groups()
                if not val.startswith("0x"):
                    val = "0x" + val
                expect_data[f"x{int(reg_num)}"] = val.lower()
                continue

            # Fallback to key-value pairs (e.g., x1 = 0x...)
            match = re.search(r"(x\d+|pc)\s*[:=]\s*(0x[0-9a-fA-F]+|\d+)", line, re.IGNORECASE)
            if match:
                key, val = match.groups()
                if not val.startswith("0x"):
                    val = hex(int(val))
                expect_data[key.lower()] = val.lower()
                
    return expect_data

def run_tests():
    hex_files = glob.glob("sw/*.hex")
    if not hex_files:
        print("[WARNING] No test .hex files found in sw/")
        return

    print(f"\n[INFO] Running regression suite across {len(hex_files)} test(s)...\n")
    
    passed = 0
    failed = 0
    skipped = 0

    for hex_path in sorted(hex_files):
        test_name = os.path.basename(hex_path)
        expect_path = hex_path.replace(".hex", ".expect")
        
        print(f"--- Test: {test_name} ---")

        if os.path.exists(SIM_EXEC):
            os.remove(SIM_EXEC)

        compile_cmd = [
            "iverilog", "-g2001", "-Irtl", 
            f'-DINIT_FILE="{hex_path}"', 
            "-o", SIM_EXEC, TB_FILE
        ] + RTL_FILES
        
        comp_res = subprocess.run(compile_cmd, capture_output=True, text=True)
        if comp_res.returncode != 0:
            print(f"  [ERROR] Compilation failed:\n{comp_res.stderr}")
            failed += 1
            continue

        sim_res = subprocess.run(["vvp", SIM_EXEC], capture_output=True, text=True)
        sim_output = sim_res.stdout

        for line in sim_output.splitlines():
            if "Loading instruction memory" in line or "Final PC" in line or "Register File Snapshot" in line or "x" in line:
                print(f"  {line}")

        if os.path.exists(expect_path):
            expect_data = parse_expect_file(expect_path)
            sim_data = parse_simulation_output(sim_output)
            
            if not expect_data:
                print(f"  [INFO] Expect file format not recognized. Skipping check.")
                skipped += 1
            else:
                mismatch = False
                for key, expected_val in expect_data.items():
                    actual_val = sim_data.get(key, "unknown")
                    try:
                        match_result = int(expected_val, 16) == int(actual_val, 16)
                    except ValueError:
                        match_result = (expected_val == actual_val)
                        
                    if not match_result:
                        print(f"  [MISMATCH] {key}: Expected {expected_val}, Got {actual_val}")
                        mismatch = True
                
                if mismatch:
                    print(f"  RESULT: ❌ FAIL")
                    failed += 1
                else:
                    print(f"  RESULT: ✔️ PASS")
                    passed += 1
        else:
            print(f"  [INFO] No .expect file found.")
            skipped += 1
        
        print("-" * 40)

    print(f"\n[SUMMARY] Passed: {passed} | Failed: {failed} | Skipped: {skipped}")

if __name__ == "__main__":
    run_tests()