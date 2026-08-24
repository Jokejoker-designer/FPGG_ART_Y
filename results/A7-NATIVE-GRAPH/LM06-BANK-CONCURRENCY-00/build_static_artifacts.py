"""Build LM06-BANK-CONCURRENCY-00 curated artifacts.

Evidence class: CURATED_DERIVATION (not automatically derived from DCP row math).
Fail-fast asserts check physical counts against BRAM_PHYSICAL.tsv before emit.
"""
from __future__ import annotations

import csv
from pathlib import Path

OUT = Path(__file__).resolve().parent
PHYS = OUT.parent / "LM06-BRAM-PHYS-AUDIT-00" / "BRAM_PHYSICAL.tsv"
DCP_SHA = (OUT.parent / "LM06-BRAM-PHYS-AUDIT-00" / "DCP_SHA256.txt").read_text().strip()

RAMB36 = 36864


def write_tsv(path: Path, rows: list[dict], fields: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields, delimiter="\t", lineterminator="\n")
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fields})


rows = list(csv.DictReader(PHYS.open(encoding="utf-8"), delimiter="\t"))


def count_prefix(prefixes: tuple[str, ...]) -> int:
    n = 0
    for r in rows:
        c = r["hier_cell"]
        if any(c == p or c.startswith(p.rstrip("*")) or (
            p.endswith("*") and c.startswith(p[:-1])
        ) for p in prefixes):
            # simpler matching below
            pass
    return n


def count_where(pred) -> int:
    return sum(1 for r in rows if pred(r))


n_core_ua = count_where(lambda r: r["hier_cell"].startswith("u_core/u_a/"))
n_core_uw = count_where(lambda r: "u_core/u_w" in r["hier_cell"] and "TILE" in r["hier_cell"])
n_core_snap = count_where(lambda r: r["hier_cell"].startswith("u_core/u_snap/"))
n_board_uw = count_where(lambda r: r["hier_cell"].startswith("u_w/CH"))
n_board_ua = count_where(lambda r: r["hier_cell"].startswith("u_a/mem_reg"))

assert n_core_ua == 64, f"u_core/u_a expected 64 got {n_core_ua}"
assert n_core_uw == 32, f"u_core/u_w TILE expected 32 got {n_core_uw}"
assert n_core_snap == 2, f"u_core/u_snap expected 2 got {n_core_snap}"
assert n_board_uw == 32, f"board u_w/CH expected 32 got {n_board_uw}"
assert n_board_ua == 2, f"board u_a/mem_reg expected 2 got {n_board_ua}"
assert len(rows) == 132, f"total BRAM expected 132 got {len(rows)}"

# curated tables follow (hard-coded facts cross-checked by asserts above)

# --- R0 PHYSICAL_TO_LOGICAL_BANKS ---
banks = [
    {
        "logical_bank_id": "CORE_act_ram128k16",
        "owner": "u_core/u_a",
        "rtl_module": "act_ram128k16",
        "physical_cells_glob": "u_core/u_a/mem_reg_*",
        "physical_tiles": "64",
        "logical_width": "16",
        "logical_depth": "131072",
        "ram_mode": "TDP_inferred_as_bit_slices",
        "port_topology": "PortA: RW registered; PortB: RO registered; rw_addr_collision=yes",
        "address_topology": "single 17-bit space aa()/ay()/ah(); both ports every cycle",
        "board_or_core": "CORE",
        "grouping_evidence": "shared ADDRARDADDR/CLK across 64 rw=1 tiles; 4x16 naming",
        "notes": "NOT board tile_activation",
    },
    {
        "logical_bank_id": "CORE_weight_tile_bank",
        "owner": "u_core/u_w/TILE.u_bank",
        "rtl_module": "weight_bram_tdp8 DEPTH=131072",
        "physical_cells_glob": "u_core/u_w/TILE.u_bank/mem_reg_*",
        "physical_tiles": "32",
        "logical_width": "8",
        "logical_depth": "131072",
        "ram_mode": "TDP_inferred_as_bit_slices",
        "port_topology": "PortA: RW; PortB: RO; silicon SIM_FULL=0 path",
        "address_topology": "loc_of(addr) within resident region; miss refill serialized",
        "board_or_core": "CORE",
        "grouping_evidence": "32 rw=1 tiles under TILE.u_bank",
        "notes": "Silicon weight working set; not FULL 1M array",
    },
    {
        "logical_bank_id": "CORE_snap_ram4k16",
        "owner": "u_core/u_snap",
        "rtl_module": "snap_ram4k16",
        "physical_cells_glob": "u_core/u_snap/mem_reg_*",
        "physical_tiles": "2",
        "logical_width": "16",
        "logical_depth": "4096",
        "ram_mode": "TDP_x9_aspect",
        "port_topology": "async same-clk R@raddr W@waddr",
        "address_topology": "12-bit waddr/raddr",
        "board_or_core": "CORE",
        "grouping_evidence": "2x TDP rw=9",
        "notes": "",
    },
    {
        "logical_bank_id": "BOARD_tile_weight_pingpong",
        "owner": "u_w/CH[*]",
        "rtl_module": "tile_weight_pingpong",
        "physical_cells_glob": "u_w/CH[*].ram{0,1}_reg_*",
        "physical_tiles": "32",
        "logical_width": "128_per_CH",
        "logical_depth": "256",
        "ram_mode": "SDP_x72_shell_pair_per_128b",
        "port_topology": "8 CH; wr one bank; rd other/same via rd_bank; all CH read each cycle",
        "address_topology": "wr_k/rd_k 8-bit; wr_chunk selects CH",
        "board_or_core": "BOARD_TENSOR",
        "grouping_evidence": "RTL generate CH[0:7] ram0/ram1; phys 32 SDP",
        "notes": "LM04-class tensor path co-resident on frozen LM06 bit; NOT core u_w",
    },
    {
        "logical_bank_id": "BOARD_tile_activation",
        "owner": "u_a/mem_reg_*",
        "rtl_module": "tile_activation",
        "physical_cells_glob": "u_a/mem_reg_0,u_a/mem_reg_1",
        "physical_tiles": "2",
        "logical_width": "128",
        "logical_depth": "256",
        "ram_mode": "SDP_104b_as_72p32",
        "port_topology": "single write+read same clk (SDP-like)",
        "address_topology": "wr_k/rd_k 8-bit",
        "board_or_core": "BOARD_TENSOR",
        "grouping_evidence": "2 SDP tiles; RTL 256x128",
        "notes": "NOT core act_ram128k16",
    },
]

write_tsv(
    OUT / "PHYSICAL_TO_LOGICAL_BANKS.tsv",
    banks,
    list(banks[0].keys()),
)

# --- R1 STATIC_PORT_TOPOLOGY ---
topo = [
    {
        "logical_bank_id": "CORE_act_ram128k16",
        "read_ports": "2",
        "write_ports": "1 (port A)",
        "addresses": "addr_a, addr_b independent",
        "enable_structure": "implicit always-on clock enables",
        "write_enable": "we_a on port A",
        "collision_mode": "READ_FIRST-ish / rw_addr_collision=yes",
        "output_reg": "yes (always_ff)",
        "producer_stage": "tiny_gpt803k_core FSM (awe/aaddr)",
        "consumer_stage": "MAC/ALU via ard/ard_b",
        "fanout": "core datapath",
        "static_bound_class": "DEPTH_BOUND+PORT_BOUND",
        "notes": "ATT_SC drives both ports same cycle different addresses — TRUE dual-port need",
    },
    {
        "logical_bank_id": "CORE_weight_tile_bank",
        "read_ports": "2",
        "write_ports": "1",
        "addresses": "bank_aa, bank_ab",
        "enable_structure": "always clocked",
        "write_enable": "bank_we",
        "collision_mode": "rw_addr_collision=yes",
        "output_reg": "yes",
        "producer_stage": "host load / train update / refill STORE",
        "consumer_stage": "FWD/TRAIN weight fetch",
        "fanout": "core",
        "static_bound_class": "DEPTH_BOUND+PORT_BOUND",
        "notes": "need_b forced 0: only one miss owner — reduces TRUE multi-region concurrency",
    },
    {
        "logical_bank_id": "CORE_snap_ram4k16",
        "read_ports": "1",
        "write_ports": "1",
        "addresses": "raddr,waddr may differ",
        "enable_structure": "we",
        "write_enable": "we",
        "collision_mode": "same-cycle R/W different addr OK",
        "output_reg": "yes",
        "producer_stage": "snap write phases",
        "consumer_stage": "restore/read",
        "fanout": "core",
        "static_bound_class": "CAPACITY_BOUND",
        "notes": "4096x16=65536 bits needs 2 RAMB36; topology_headroom=0 (amended)",
    },
    {
        "logical_bank_id": "BOARD_tile_weight_pingpong",
        "read_ports": "8 CH parallel read",
        "write_ports": "1 CH write/cycle (wr_chunk)",
        "addresses": "rd_k shared across CH; wr_k+wr_chunk",
        "enable_structure": "wr_en & bank select",
        "write_enable": "wr_en",
        "collision_mode": "ping/pong banks",
        "output_reg": "yes",
        "producer_stage": "ddr_tile_dma / tensor_microseq",
        "consumer_stage": "mac_array_128 via gemv/gemm",
        "fanout": "1024-bit rd_data",
        "static_bound_class": "BANKING_BOUND+WIDTH_BOUND",
        "notes": "TRUE_CONCURRENT across 8 CH each read cycle; banks exclusive by rd_bank",
    },
    {
        "logical_bank_id": "BOARD_tile_activation",
        "read_ports": "1",
        "write_ports": "1",
        "addresses": "rd_k, wr_k",
        "enable_structure": "wr_en",
        "write_enable": "wr_en",
        "collision_mode": "same array",
        "output_reg": "yes",
        "producer_stage": "tensor path",
        "consumer_stage": "gemv/gemm",
        "fanout": "128-bit row",
        "static_bound_class": "WIDTH_BOUND",
        "notes": "128b needs >=2 RAMB36 at x72 max; physical=2",
    },
]
write_tsv(OUT / "STATIC_PORT_TOPOLOGY.tsv", topo, list(topo[0].keys()))

# --- R5 PHYSICAL_LOWER_BOUNDS ---
bounds = []


def add_bound(**kw):
    bounds.append(kw)


# CORE act: depth 128K with 32K native => 4 cascades; width 16 TDP => 16 slices; 4*16=64
add_bound(
    logical_bank_id="CORE_act_ram128k16",
    N_physical="64",
    N_capacity=str((131072 * 16 + RAMB36 - 1) // RAMB36),
    N_width="16 (TDP bit-slice unit)",
    N_depth="4 (131072/32768)",
    N_ports="2 (True dual)",
    N_lower_bound="64",
    topology_headroom="0",
    limiting="DEPTH_BOUND * WIDTH_SLICE",
    notes="ceil(cap)=57 but TDP 16b x 4-deep cascade forces 64",
)

add_bound(
    logical_bank_id="CORE_weight_tile_bank",
    N_physical="32",
    N_capacity=str((131072 * 8 + RAMB36 - 1) // RAMB36),
    N_width="8",
    N_depth="4",
    N_ports="2",
    N_lower_bound="32",
    topology_headroom="0",
    limiting="DEPTH_BOUND * WIDTH_SLICE",
    notes="ceil(cap)=29; 8*4=32 matches physical",
)

add_bound(
    logical_bank_id="CORE_snap_ram4k16",
    N_physical="2",
    N_capacity=str((4096 * 16 + RAMB36 - 1) // RAMB36),  # 65536 bits -> 2
    N_width="2 (16b)",
    N_depth="1",
    N_ports="1-2",
    N_lower_bound="2",
    topology_headroom="0",
    limiting="CAPACITY_BOUND",
    notes="AMENDED: prior N_capacity=1/headroom=1 WITHDRAWN; ceil(65536/36864)=2",
)

# Board weight: 16 arrays * 128b*256=32Kb each => 1 tile capacity each but width 128 needs 2 tiles (72+56)
add_bound(
    logical_bank_id="BOARD_tile_weight_pingpong",
    N_physical="32",
    N_capacity="16",
    N_width="32 (16 arrays * 2 tiles for 128b)",
    N_depth="1",
    N_ports="8 concurrent CH reads",
    N_lower_bound="32",
    topology_headroom="0",
    limiting="WIDTH_BOUND per 128b array",
    notes="If ping/pong never overlap live contents, overlay could cut banks — NEEDS_EXPERIMENT lifetime",
)

add_bound(
    logical_bank_id="BOARD_tile_activation",
    N_physical="2",
    N_capacity="1",
    N_width="2 (128b > 72)",
    N_depth="1",
    N_ports="1",
    N_lower_bound="2",
    topology_headroom="0",
    limiting="WIDTH_BOUND",
    notes="32b tail in x72 shell is waste inside tile, not removable tile",
)

write_tsv(OUT / "PHYSICAL_LOWER_BOUNDS.tsv", bounds, list(bounds[0].keys()))

# --- R4 DEPENDENCY_SUMMARY (RTL-derived) ---
deps = [
    {
        "bank": "CORE_act_ram128k16",
        "pattern": "ST_ATT_SC dual read Q/K",
        "raw_war_waw": "RAW none (two reads); later write awe separate states",
        "same_cycle_parallel": "YES aaddr & aaddr_b",
        "class": "TRUE_CONCURRENT",
        "evidence": "tiny_gpt803k_core.sv ST_ATT_SC sub0 sets both addresses; sub2 uses ard&ard_b",
        "serializable_inference": "NO without doubling cycles for score MAC",
    },
    {
        "bank": "CORE_act_ram128k16",
        "pattern": "ST_ADD dual read",
        "raw_war_waw": "two reads",
        "same_cycle_parallel": "YES",
        "class": "TRUE_CONCURRENT",
        "evidence": "ADD debug path uses ard+ard_b",
        "serializable_inference": "possible but 2x latency — NEEDS_EXPERIMENT",
    },
    {
        "bank": "CORE_weight_tile_bank",
        "pattern": "port A compute + port B helper",
        "raw_war_waw": "need_b=0 prevents second miss",
        "same_cycle_parallel": "YES reads both ports; miss serialized",
        "class": "TRUE_CONCURRENT for peeks; SERIALIZABLE_INFERENCE for multi-region",
        "evidence": "weight_tile803k.sv assign need_b=0",
        "serializable_inference": "multi-region already serialized by design",
    },
    {
        "bank": "BOARD_tile_weight_pingpong",
        "pattern": "8 CH parallel read",
        "raw_war_waw": "N/A (read fanout)",
        "same_cycle_parallel": "YES by construction",
        "class": "TRUE_CONCURRENT",
        "evidence": "rd_data concatenates CH[0:7]",
        "serializable_inference": "serializing CH would break 1024b MAC beat",
    },
    {
        "bank": "BOARD_tile_weight_pingpong",
        "pattern": "ram0 vs ram1 pingpong",
        "raw_war_waw": "producer fills one bank while consumer reads other",
        "same_cycle_parallel": "banks distinct",
        "class": "TRUE_CONCURRENT across banks when overlap",
        "evidence": "tile_weight_pingpong dual arrays",
        "serializable_inference": "overlay only if DMA fill never overlaps compute — NEEDS_EXPERIMENT",
    },
]
write_tsv(OUT / "DEPENDENCY_SUMMARY.tsv", deps, list(deps[0].keys()))

# --- R3 lifetimes placeholder (filled more after sim) ---
lives = [
    {
        "logical_bank_id": "CORE_act_ram128k16",
        "birth_cycle": "UNKNOWN",
        "first_write": "EMB/LN phases (DERIVED)",
        "first_read": "same / subsequent",
        "last_write": "UNKNOWN without full trace",
        "last_read": "UNKNOWN",
        "death_cycle": "UNKNOWN",
        "M_peak_bits": "2097152 (full array capacity; peak-live UNKNOWN)",
        "simultaneously_live_vs_accessed": "array persists whole FWD; accessed subset each cycle",
        "notes": "lifetime != access; full mem not rewritten each token",
    },
    {
        "logical_bank_id": "CORE_weight_tile_bank",
        "birth_cycle": "region fill",
        "first_write": "DMA STORE / host",
        "first_read": "compute after resident",
        "last_write": "update/flush",
        "last_read": "until region miss",
        "death_cycle": "evict on miss",
        "M_peak_bits": "1048576",
        "simultaneously_live_vs_accessed": "one region resident; accessed 1-2 addrs/cycle",
        "notes": "working-set already region-folded vs full 802k",
    },
    {
        "logical_bank_id": "BOARD_tile_weight_pingpong",
        "birth_cycle": "DMA fill bank",
        "first_write": "wr_en",
        "first_read": "rd after tag match",
        "last_write": "bank rewrite",
        "last_read": "until swap",
        "death_cycle": "tag invalidate (seq)",
        "M_peak_bits": "524288",
        "simultaneously_live_vs_accessed": "both banks may be live; one read bank accessed",
        "notes": "lifetime overlay candidate if tags prove exclusive",
    },
]
write_tsv(OUT / "BANK_LIFETIMES.tsv", lives, list(lives[0].keys()))

# concurrency table skeleton
conc = [
    {
        "logical_bank_id": "CORE_act_ram128k16",
        "max_simultaneous_read_ports_required": "2",
        "max_simultaneous_write_ports_required": "1",
        "max_independent_addresses_per_cycle": "2",
        "max_simultaneous_read_slices": "16 (full width; not 64 tiles)",
        "source": "RTL_FSM + phys slice count",
        "true_vs_overbank": "TRUE dual-port; tile count from depth*width not over-banking",
    },
    {
        "logical_bank_id": "CORE_weight_tile_bank",
        "max_simultaneous_read_ports_required": "2",
        "max_simultaneous_write_ports_required": "1",
        "max_independent_addresses_per_cycle": "2",
        "max_simultaneous_read_slices": "8",
        "source": "RTL",
        "true_vs_overbank": "TRUE dual-port; region miss already serialized",
    },
    {
        "logical_bank_id": "BOARD_tile_weight_pingpong",
        "max_simultaneous_read_ports_required": "8_CH",
        "max_simultaneous_write_ports_required": "1_CH",
        "max_independent_addresses_per_cycle": "1_index_x_8CH",
        "max_simultaneous_read_slices": "1024_bits",
        "source": "RTL",
        "true_vs_overbank": "TRUE 8-way CH concurrency; pingpong may be lifetime opportunity",
    },
]
write_tsv(OUT / "BANK_CONCURRENCY.tsv", conc, list(conc[0].keys()))

# candidates
cands = [
    {
        "id": "A_BANK_FOLD",
        "applies_to": "CORE_act optional serialize ATT dual-read",
        "BRAM_delta": "0 (ports still need TDP fabric)",
        "cycles_per_token_delta": "+large (2x ATT_SC)",
        "DDR_bytes_per_token_delta": "0",
        "LUT_delta": "small",
        "FF_delta": "small",
        "timing_risk": "low",
        "implementation_complexity": "med",
        "rho_bytes": "n/a",
        "rho_cycles": "inf (no BRAM save)",
        "pareto_note": "dominated — no BRAM save",
    },
    {
        "id": "B_MULTIPUMP",
        "applies_to": "CORE_act / CORE_weight",
        "BRAM_delta": "UNKNOWN maybe reduce depth cascades if 2x clock services 1 port twice",
        "cycles_per_token_delta": "0 if hidden",
        "DDR_bytes_per_token_delta": "0",
        "LUT_delta": "CDC+control",
        "FF_delta": "CDC",
        "timing_risk": "HIGH",
        "implementation_complexity": "HIGH",
        "rho_bytes": "UNKNOWN",
        "rho_cycles": "UNKNOWN",
        "pareto_note": "model only; N_lower still width*depth at 100MHz fabric",
    },
    {
        "id": "C_TAIL_COPACK",
        "applies_to": "BOARD 17 WIDTH_BOUND tails",
        "BRAM_delta": "0 unless two 32b tails share address/en/lifetime",
        "cycles_per_token_delta": "0",
        "DDR_bytes_per_token_delta": "0",
        "LUT_delta": "pack mux",
        "FF_delta": "small",
        "timing_risk": "med",
        "implementation_complexity": "med",
        "rho_bytes": "n/a if 0 save",
        "rho_cycles": "n/a",
        "pareto_note": "FACT: each 128b array already 2 tiles; co-pack across CH needs identical rd_k timing — possible for all CH same rd_k YES — but merging CH reduces MAC width",
    },
    {
        "id": "D_LUTRAM_SNAP",
        "applies_to": "CORE_snap 4096x16",
        "BRAM_delta": "-2 CROSS_RESOURCE BRAM->LUTRAM",
        "cycles_per_token_delta": "0",
        "DDR_bytes_per_token_delta": "0",
        "LUT_delta": "~1024+ LUT6 class NEEDS_SYNTH",
        "FF_delta": "mod",
        "timing_risk": "med",
        "implementation_complexity": "low-med",
        "rho_bytes": "0",
        "rho_cycles": "0",
        "pareto_note": "AMENDED: not topology headroom; migration only",
    },
    {
        "id": "E_STREAM_THROUGH",
        "applies_to": "short-lived act temps",
        "BRAM_delta": "0 unless removes act regions",
        "cycles_per_token_delta": "0-neg",
        "DDR_bytes_per_token_delta": "0",
        "LUT_delta": "SRL/FF",
        "FF_delta": "up",
        "timing_risk": "med",
        "implementation_complexity": "high (law)",
        "rho_bytes": "UNKNOWN",
        "rho_cycles": "UNKNOWN",
        "pareto_note": "NEEDS_EXPERIMENT lifetime map",
    },
    {
        "id": "F_PHASE_OVERLAY",
        "applies_to": "BOARD pingpong banks; GRAPH vs LM (doctrine)",
        "BRAM_delta": "up to -16 board weight if banks never dual-live",
        "cycles_per_token_delta": "0 or stall+",
        "DDR_bytes_per_token_delta": "0-up",
        "LUT_delta": "mux/tags",
        "FF_delta": "tags",
        "timing_risk": "med",
        "implementation_complexity": "high",
        "rho_bytes": "depends",
        "rho_cycles": "depends",
        "pareto_note": "largest theoretical board save; requires tag/lifetime proof",
    },
    {
        "id": "G_DDR_WS",
        "applies_to": "CORE_act / already on weights",
        "BRAM_delta": "large if act tiled like weights",
        "cycles_per_token_delta": "+stalls",
        "DDR_bytes_per_token_delta": "+large",
        "LUT_delta": "DMA",
        "FF_delta": "DMA",
        "timing_risk": "high",
        "implementation_complexity": "very high",
        "rho_bytes": "high (bad)",
        "rho_cycles": "high (bad)",
        "pareto_note": "weights already DDR-tiled; act DDR is last resort",
    },
]
write_tsv(OUT / "OPTIMIZATION_CANDIDATES.tsv", cands, list(cands[0].keys()))

(OUT / "DCP_SHA256.txt").write_text(DCP_SHA + "\n", encoding="utf-8")
print("static artifacts written", OUT)
print("dcp", DCP_SHA)
