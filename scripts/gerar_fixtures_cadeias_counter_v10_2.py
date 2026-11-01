#!/usr/bin/env python3
"""Gera fixtures temporais quadro a quadro (estados 8..11 e 17..19) a partir das capturas reais do MAME 0.289."""

import csv
import hashlib
import json
import os

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
LAB_DIR = os.path.join(BASE_DIR, "laboratorio", "auto_20261028_232043_038647")
OUT_PATH = os.path.join(BASE_DIR, "godot", "data", "chain_counter_timeline_fixtures.json")

CASES_SPEC = [
    {"id": "crash_red4", "category": "simple_destruction", "rotate1": False, "rotate2": False, "both": False, "delay2": 0, "max_frame": 140},
    {"id": "crash_pair", "category": "simple_destruction", "rotate1": False, "rotate2": False, "both": False, "delay2": 0, "max_frame": 120},
    {"id": "power_crash4", "category": "simple_destruction", "rotate1": True, "rotate2": False, "both": False, "delay2": 0, "max_frame": 130},
    {"id": "counter_adjacent_same", "category": "simple_destruction", "rotate1": False, "rotate2": False, "both": False, "delay2": 0, "max_frame": 140},
    {"id": "counter_adjacent_other", "category": "simple_destruction", "rotate1": False, "rotate2": False, "both": False, "delay2": 0, "max_frame": 140},
    {"id": "power_rigid_gravity", "category": "intermediate_gravity", "rotate1": False, "rotate2": False, "both": False, "delay2": 0, "max_frame": 120},
    {"id": "combo_two_colors", "category": "multi_wave_chains", "rotate1": False, "rotate2": False, "both": False, "delay2": 0, "max_frame": 290},
    {"id": "combo_three_colors", "category": "multi_wave_chains", "rotate1": False, "rotate2": False, "both": False, "delay2": 0, "max_frame": 290},
    {"id": "combo_two_powers", "category": "multi_wave_chains", "rotate1": False, "rotate2": False, "both": False, "delay2": 0, "max_frame": 290},
    {"id": "chain_2", "category": "multi_wave_chains", "rotate1": False, "rotate2": False, "both": False, "delay2": 0, "max_frame": 290},
    {"id": "chain_3", "category": "multi_wave_chains", "rotate1": False, "rotate2": False, "both": False, "delay2": 0, "max_frame": 290},
    {"id": "chain_3_counter", "category": "multi_wave_chains", "rotate1": False, "rotate2": False, "both": False, "delay2": 0, "max_frame": 290},
    {"id": "chain_3_larger", "category": "intermediate_gravity", "rotate1": False, "rotate2": False, "both": False, "delay2": 0, "max_frame": 290},
    {"id": "attack_red8", "category": "counter_delivery", "rotate1": True, "rotate2": False, "both": False, "delay2": 0, "max_frame": 290},
    {"id": "attack_red12", "category": "counter_fall", "rotate1": True, "rotate2": False, "both": False, "delay2": 0, "max_frame": 290},
    {"id": "attack_p2_red12", "category": "counter_fall", "rotate1": False, "rotate2": True, "both": True, "delay2": 0, "max_frame": 396},
    {"id": "attack_cancel", "category": "simultaneous_attacks", "rotate1": False, "rotate2": False, "both": True, "delay2": 0, "max_frame": 180},
    {"id": "counterattack_4_4", "category": "simultaneous_attacks", "rotate1": False, "rotate2": False, "both": True, "delay2": 30, "max_frame": 210},
    {"id": "counterattack_4_8", "category": "simultaneous_attacks", "rotate1": False, "rotate2": False, "both": True, "delay2": 30, "max_frame": 210},
    {"id": "counterattack_8_5", "category": "simultaneous_attacks", "rotate1": False, "rotate2": False, "both": True, "delay2": 30, "max_frame": 210},
    {"id": "counterattack_8_8", "category": "simultaneous_attacks", "rotate1": False, "rotate2": False, "both": True, "delay2": 30, "max_frame": 210},
    {"id": "counterattack_large_2_4", "category": "simultaneous_attacks", "rotate1": True, "rotate2": True, "both": True, "delay2": 35, "max_frame": 250},
]


def word(ram: bytes, addr: int) -> int:
    return (ram[addr] << 8) | ram[addr + 1]


def sword(ram: bytes, addr: int) -> int:
    v = word(ram, addr)
    return v - 65536 if v >= 32768 else v


def u32(ram: bytes, addr: int) -> int:
    return (ram[addr] << 24) | (ram[addr + 1] << 16) | (ram[addr + 2] << 8) | ram[addr + 3]


def read_grid(ram: bytes, base_addr: int) -> str:
    vals = []
    for y in range(14):
        for x in range(6):
            vals.append(f"{word(ram, base_addr + y * 16 + 2 * (x + 1)):04X}")
    return ":".join(vals)


def extract_player_init(ram: bytes, base_addr: int, grid_addr: int) -> dict:
    return {
        "x": word(ram, base_addr + 0x10),
        "y": word(ram, base_addr + 0x14),
        "offset": sword(ram, base_addr + 0x242),
        "rotation": ram[base_addr + 0x170],
        "contact": ram[base_addr + 0x176],
        "phase": ram[base_addr + 0x17E],
        "turn": word(ram, base_addr + 0x1A0),
        "pivot": word(ram, base_addr + 0x152),
        "satellite": word(ram, base_addr + 0x154),
        "next_pivot": word(ram, base_addr + 0x156),
        "next_satellite": word(ram, base_addr + 0x158),
        "previous_input": word(ram, base_addr + 0x142),
        "pair_age": word(ram, base_addr + 0x1A6),
        "down_counter": word(ram, base_addr + 0x320),
        "down_timer": ram[base_addr + 0x1A9],
        "fall_countdown": ram[base_addr + 0x15E],
        "fall_interval": ram[base_addr + 0x18A],
        "fall_offset": sword(ram, base_addr + 0x388),
        "fall_increment": sword(ram, base_addr + 0x27C),
        "fall_start": ram[base_addr + 0x27E] != 0,
        "contact_count": ram[base_addr + 0x1A8],
        "upkicks": word(ram, base_addr + 0x314),
        "rotation_disabled": ram[base_addr + 0x316] != 0,
        "horizontal_timer": word(ram, base_addr + 0x188),
        "score": u32(ram, base_addr + 0xAA),
        "char_id": ram[base_addr + 0x82],
        "grid": read_grid(ram, grid_addr),
    }


def main() -> None:
    with open(os.path.join(LAB_DIR, "mechanics.csv"), "r", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    out_cases = []
    for spec in CASES_SPEC:
        cid = spec["id"]
        seed_path = os.path.join(LAB_DIR, "captures", f"{cid}_seed.bin")
        with open(seed_path, "rb") as f:
            seed_ram = f.read()
        sha256 = hashlib.sha256(seed_ram).hexdigest()
        p1_init = extract_player_init(seed_ram, 0x8300, 0xAB00)
        p2_init = extract_player_init(seed_ram, 0x8700, 0xAD00)
        c_rows = [r for r in rows if r["case"] == cid and int(r["frame"]) <= spec["max_frame"]]
        samples = []
        for r in c_rows:
            fn = int(r["frame"])
            sample = {
                "frame": fn,
                "turn1": int(r["turn1"]),
                "turn2": int(r["turn2"]),
                "score1": int(r["score1"]),
                "score2": int(r["score2"]),
                "pending1_hud": int(r["pending1"]),
                "pending2_hud": int(r["pending2"]),
                "row1": int(r["row1"]),
                "row2": int(r["row2"]),
                "perm1": int(r["permutation1"]),
                "perm2": int(r["permutation2"]),
                "grid1": r["grid1"],
                "grid2": r["grid2"],
            }
            snap_path = os.path.join(LAB_DIR, "captures", f"{cid}_f{fn:04d}.bin")
            if os.path.exists(snap_path):
                with open(snap_path, "rb") as sf:
                    sram = sf.read()
                sample["phase1"] = sram[0x847E]
                sample["phase2"] = sram[0x887E]
                sample["pending1_raw"] = sram[0x889E]
                sample["pending2_raw"] = sram[0x849E]
            samples.append(sample)
        out_cases.append({
            "id": cid,
            "category": spec["category"],
            "source_session": "auto_20261028_232043_038647",
            "seed_ram_sha256": sha256,
            "rotate1": spec["rotate1"],
            "rotate2": spec["rotate2"],
            "both": spec["both"],
            "delay2": spec["delay2"],
            "p1_init": p1_init,
            "p2_init": p2_init,
            "samples": samples,
        })

    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump({"cases": out_cases}, f, indent=2)
    print(f"Wrote {len(out_cases)} cases ({sum(len(c['samples']) for c in out_cases)} samples) to {OUT_PATH}")


if __name__ == "__main__":
    main()
