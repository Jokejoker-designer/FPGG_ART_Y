"""Generate LM-06 core/persist/top/python from LM-05 sources."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def xf_core(src: str) -> str:
    s = src
    reps = [
        ("import a7lm05_pkg::*", "import a7lm06_pkg::*"),
        ("module a7lm05_logits_lutram", "module a7lm06_logits_lutram"),
        ("input  logic [8:0]         waddr,", "input  logic [9:0]         waddr,"),
        ("input  logic [8:0]         raddr,", "input  logic [9:0]         raddr,"),
        ("logic signed [31:0] mem [0:511];", "logic signed [31:0] mem [0:1023];"),
        ("// Sequential 4-layer 4-head TinyGPT. law_id lm05-signsgd-v1.",
         "// Sequential 4-layer 4-head TinyGPT. law_id lm06-signsgd-v1."),
        ("// Counters are 9-bit so V=512, D=96, FF=192 do not wrap.",
         "// Counters: V=1024 10-bit, C=128 7-bit, D/FF fit in 9-bit."),
        ("module tiny_gpt399k_core #(", "module tiny_gpt803k_core #("),
        ("    input  logic [18:0]        mem_addr,", "    input  logic [19:0]        mem_addr,"),
        ("    input  logic [5:0]         ctx_idx,", "    input  logic [6:0]         ctx_idx,"),
        ("    input  logic [5:0]         ctx_n_in,", "    input  logic [6:0]         ctx_n_in,"),
        ("    input  logic [8:0]         tgt_in,", "    input  logic [9:0]         tgt_in,"),
        ("    output logic [8:0]         pred,", "    output logic [9:0]         pred,"),
        ("    logic [5:0] ntok, tok_i, tok_j;", "    logic [6:0] ntok, tok_i, tok_j;"),
        ("    logic [7:0] tok [0:63];", "    logic [7:0] tok [0:127];"),
        ("    logic [8:0] tgt;", "    logic [9:0] tgt;"),
        ("    logic [8:0] vix;", "    logic [9:0] vix;"),
        ("    logic signed [31:0] score [0:63];", "    logic signed [31:0] score [0:127];"),
        ("    logic [7:0]         exps [0:63];", "    logic [7:0]         exps [0:127];"),
        ("    logic [7:0]         e_last [0:3][0:63];", "    logic [7:0]         e_last [0:3][0:127];"),
        ("    logic [18:0]        waddr, caddr, ck_raddr;", "    logic [19:0]        waddr, caddr, ck_raddr;"),
        ("    logic [15:0]        aaddr, aaddr_b;", "    logic [16:0]        aaddr, aaddr_b;"),
        ("    logic [7:0]         smx_e [0:511];", "    logic [7:0]         smx_e [0:1023];"),
        ("    logic [8:0]         arg_best;", "    logic [9:0]         arg_best;"),
        ("    logic [18:0]        wbase;", "    logic [19:0]        wbase;"),
        ("    (* ram_style = \"registers\" *) logic signed [31:0] dY [0:95];",
         "    (* ram_style = \"registers\" *) logic signed [31:0] dY [0:127];"),
        ("    (* ram_style = \"registers\" *) logic signed [31:0] dH [0:95];",
         "    (* ram_style = \"registers\" *) logic signed [31:0] dH [0:127];"),
        ("    (* ram_style = \"registers\" *) logic signed [31:0] dHid [0:191];",
         "    (* ram_style = \"registers\" *) logic signed [31:0] dHid [0:255];"),
        ("    logic [10:0]        snap_waddr, snap_raddr;", "    logic [11:0]        snap_waddr, snap_raddr;"),
        ("    a7lm05_logits_lutram u_logits (", "    a7lm06_logits_lutram u_logits ("),
        ("    weight_tile399k #(.SIM_FULL(SIM_FULL)) u_w (",
         "    weight_tile803k #(.SIM_FULL(SIM_FULL)) u_w ("),
        ("        .cached_ly(), .dirty(),", "        .cached_rg(), .dirty(),"),
        ("    logic [18:0] w_addr_b;", "    logic [19:0] w_addr_b;"),
        ("    assign w_addr_b = ((st == ST_FOLD) || (st == ST_SNAP)) ? 19'd0 : caddr;",
         "    assign w_addr_b = ((st == ST_FOLD) || (st == ST_SNAP)) ? waddr : caddr;"),
        ("            ntok <= 6'd0;", "            ntok <= 7'd0;"),
        ("            waddr <= 19'd0;", "            waddr <= 20'd0;"),
        ("            caddr <= 19'd0;", "            caddr <= 20'd0;"),
        ("            ck_raddr <= 19'd0;", "            ck_raddr <= 20'd0;"),
        ("                if (ctx_idx == 6'd0)", "                if (ctx_idx == 7'd0)"),
        ("                        tok[ctx_idx + ii[5:0]] <= ctx_pack[8*ii +: 8];",
         "                        tok[ctx_idx + ii[6:0]] <= ctx_pack[8*ii +: 8];"),
        ("                            xor32 <= 32'd0; add32 <= 32'd0; caddr <= 19'd0; waddr <= 19'd0; sub <= 4'd0; st <= ST_FOLD;",
         "                            xor32 <= 32'd0; add32 <= 32'd0; caddr <= 20'd0; waddr <= 20'd0; sub <= 4'd0; st <= ST_FOLD;"),
        ("                            ly <= 2'd0; tok_i <= 6'd0; dim <= 9'd0; sub <= 4'd0; acc <= 64'sd0; st <= ST_EMB;",
         "                            ly <= 2'd0; tok_i <= 7'd0; dim <= 9'd0; sub <= 4'd0; acc <= 64'sd0; st <= ST_EMB;"),
        ("                        ntok <= 6'd1;", "                        ntok <= 7'd1;"),
        ("                    ly <= 2'd0; tok_i <= 6'd0; dim <= 9'd0; sub <= 4'd0; acc <= 64'sd0; st <= ST_EMB;",
         "                    ly <= 2'd0; tok_i <= 7'd0; dim <= 9'd0; sub <= 4'd0; acc <= 64'sd0; st <= ST_EMB;"),
        ("19'(OFF_TOK)", "20'(OFF_TOK)"),
        ("19'(OFF_POS)", "20'(OFF_POS)"),
        ("19'(OFF_HEAD)", "20'(OFF_HEAD)"),
        ("19'(tok[", "20'(tok["),
        ("19'(tok_i)", "20'(tok_i)"),
        ("19'(D)", "20'(D)"),
        ("19'(dim)", "20'(dim)"),
        ("19'(NPARAM)", "20'(NPARAM)"),
        ("19'(row)", "20'(row)"),
        ("19'(ncols)", "20'(ncols)"),
        ("19'(col)", "20'(col)"),
        ("19'(vix)", "20'(vix)"),
        ("19'(last_tok", "20'(last_tok"),
        ("layer_base(ly) + 19'(", "layer_base(ly) + 20'("),
        ("wbase + 19'(", "wbase + 20'("),
        ("tok_i <= 6'd0", "tok_i <= 7'd0"),
        ("tok_j <= 6'd0", "tok_j <= 7'd0"),
        ("tok_i + 6'd1", "tok_i + 7'd1"),
        ("tok_j + 6'd1", "tok_j + 7'd1"),
        ("if (tok_j == 6'd63)", "if (tok_j == 7'd127)"),
        ("hix * 5'd24", "hix * 5'd32"),
        ("function automatic [5:0] last_tok(input [5:0] n);\n        return (n == 6'd0) ? 6'd0 : (n - 6'd1);",
         "function automatic [6:0] last_tok(input [6:0] n);\n        return (n == 7'd0) ? 7'd0 : (n - 7'd1);"),
        ("function automatic [15:0] aa(input [1:0] ly_, input [2:0] t, input [5:0] tk, input [6:0] d);\n        return 16'(t) * 16'(ACT_STRIDE) + 16'(tk) * 16'(D) + 16'(d);",
         "function automatic [16:0] aa(input [1:0] ly_, input [2:0] t, input [6:0] tk, input [6:0] d);\n        return 17'(t) * 17'(ACT_STRIDE) + 17'(tk) * 17'(D) + 17'(d);"),
        ("function automatic [15:0] ah(input [1:0] ly_, input [5:0] tk, input [7:0] hh);",
         "function automatic [16:0] ah(input [1:0] ly_, input [6:0] tk, input [8:0] hh);"),
        ("        return aa(ly_, t, tk, d);", "        return aa(ly_, t, tk, d);"),
        ("function automatic [15:0] ay(input [1:0] ly_, input [5:0] tk, input [6:0] d);",
         "function automatic [16:0] ay(input [1:0] ly_, input [6:0] tk, input [6:0] d);"),
        ("function automatic [10:0] snap_n1(input [1:0] ly_, input [6:0] d);\n        return 11'(ly_) * 11'(D) + 11'(d);",
         "function automatic [11:0] snap_n1(input [1:0] ly_, input [6:0] d);\n        return 12'(ly_) * 12'(D) + 12'(d);"),
        ("function automatic [10:0] snap_n2(input [1:0] ly_, input [6:0] d);\n        return 11'd384 + 11'(ly_) * 11'(D) + 11'(d);",
         "function automatic [11:0] snap_n2(input [1:0] ly_, input [6:0] d);\n        return 12'd512 + 12'(ly_) * 12'(D) + 12'(d);"),
        ("function automatic [10:0] snap_at(input [1:0] ly_, input [6:0] d);\n        return 11'd768 + 11'(ly_) * 11'(D) + 11'(d);",
         "function automatic [11:0] snap_at(input [1:0] ly_, input [6:0] d);\n        return 12'd1024 + 12'(ly_) * 12'(D) + 12'(d);"),
        ("function automatic [10:0] snap_h(input [1:0] ly_, input [7:0] hh);\n        return 11'd1152 + 11'(ly_) * 11'(FF) + 11'(hh);",
         "function automatic [11:0] snap_h(input [1:0] ly_, input [8:0] hh);\n        return 12'd1536 + 12'(ly_) * 12'(FF) + 12'(hh);"),
        ("    act_ram48k u_a (\n        .clk(clk), .we_a(awe), .addr_a(aaddr), .wdata_a(awd), .rdata_a(ard),\n        .addr_b(aaddr_b), .rdata_b(ard_b)\n    );\n    snap_ram16 u_snap (",
         "    logic signed [15:0] ard16, ard_b16, awd16;\n    assign awd16 = sat16(awd);\n    assign ard = {{16{ard16[15]}}, ard16};\n    assign ard_b = {{16{ard_b16[15]}}, ard_b16};\n    act_ram128k16 u_a (\n        .clk(clk), .we_a(awe), .addr_a(aaddr), .wdata_a(awd16), .rdata_a(ard16),\n        .addr_b(aaddr_b), .rdata_b(ard_b16)\n    );\n    snap_ram4k16 u_snap ("),
        ("   aa(t,tk,d) = t*6144 + tk*96 + d          t=0..7 → 49152",
         "   aa(t,tk,d) = t*16384 + tk*128 + d         t=0..7 → 131072"),
        ("    // Dense 48K map. ly is reused: last-token bwd lives in n1/n2/a/hid_last.",
         "    // Dense 128K INT16 map. ly is reused: last-token bwd lives in snaps."),
    ]
    for a, b in reps:
        if a not in s:
            print("WARN missing:", a[:80])
        s = s.replace(a, b)
    old_emb = """                ST_EMB: begin
                    unique case (sub)
                        4'd0: begin
                            waddr <= 20'(OFF_TOK) + 20'(tok[tok_i]) * 20'(D) + 20'(dim);
                            caddr <= 20'(OFF_POS) + 20'(tok_i) * 20'(D) + 20'(dim);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        default: begin
                            awe <= 1'b1;
                            aaddr <= aa(2'd0, 3'd0, tok_i, dim[6:0]);
                            awd <= 32'(sat16(32'(wrd) + 32'(crd)));
                            sub <= 4'd0;"""
    new_emb = """                ST_EMB: begin
                    unique case (sub)
                        4'd0: begin
                            waddr <= 20'(OFF_TOK) + 20'(tok[tok_i]) * 20'(D) + 20'(dim);
                            caddr <= 20'(OFF_TOK);
                            sub <= 4'd1;
                        end
                        4'd1: begin
                            acc[31:0] <= 32'(wrd);
                            waddr <= 20'(OFF_POS) + 20'(tok_i) * 20'(D) + 20'(dim);
                            caddr <= 20'(OFF_POS);
                            sub <= 4'd2;
                        end
                        4'd2: sub <= 4'd3;
                        default: begin
                            awe <= 1'b1;
                            aaddr <= aa(2'd0, 3'd0, tok_i, dim[6:0]);
                            awd <= 32'(sat16(acc[31:0] + 32'(wrd)));
                            sub <= 4'd0;"""
    if old_emb not in s:
        print("WARN ST_EMB block not found")
    else:
        s = s.replace(old_emb, new_emb)
    return s


def xf_persist(src: str) -> str:
    s = src
    s = s.replace("import a7lm05_pkg::*;", "import a7lm06_pkg::*;")
    s = s.replace("module lm05_persist", "module lm06_persist")
    s = s.replace("// 399360/128 = 3120 lines.", "// 802816/128 = 6272 lines.")
    s = s.replace("    output logic [18:0]  mem_addr,", "    output logic [19:0]  mem_addr,")
    s = s.replace("    logic [18:0] base;", "    logic [19:0] base;")
    s = s.replace("    logic [11:0] ch;", "    logic [12:0] ch;")
    s = s.replace("            mem_addr <= 19'd0;", "            mem_addr <= 20'd0;")
    s = s.replace("            base <= 19'd0;", "            base <= 20'd0;")
    s = s.replace("            ch <= 12'd0;", "            ch <= 13'd0;")
    s = s.replace("                        base <= 19'd0;", "                        base <= 20'd0;")
    s = s.replace("                        ch <= 12'd0;", "                        ch <= 13'd0;")
    s = s.replace("                            if (ch == 12'(NCHUNK - 1))", "                            if (ch == 13'(NCHUNK - 1))")
    s = s.replace("                                ch <= ch + 12'd1;", "                                ch <= ch + 13'd1;")
    s = s.replace("                                base <= base + 19'(CHUNK);", "                                base <= base + 20'(CHUNK);")
    return s


def xf_top(src: str) -> str:
    s = src
    s = s.replace("arty_a7_lm05_top", "arty_a7_lm06_top")
    s = s.replace("import a7lm05_pkg::*;", "import a7lm06_pkg::*;")
    s = s.replace("tiny_gpt399k_core", "tiny_gpt803k_core")
    s = s.replace("lm05_persist", "lm06_persist")
    s = s.replace("logic [18:0] mem_addr", "logic [19:0] mem_addr")
    s = s.replace("logic [18:0] mem_addr_u, mem_addr_p;", "logic [19:0] mem_addr_u, mem_addr_p;")
    s = s.replace("    logic [8:0] tgt;", "    logic [9:0] tgt;")
    s = s.replace("    logic [8:0] pred;", "    logic [9:0] pred;")
    s = s.replace("    logic [5:0] ctx_idx, ctx_n;", "    logic [6:0] ctx_idx, ctx_n;")
    s = s.replace("    logic [18:0] rd_base;", "    logic [19:0] rd_base;")
    s = s.replace("    logic [18:0] wr_base;", "    logic [19:0] wr_base;")
    s = s.replace("            rd_base <= 19'd0;", "            rd_base <= 20'd0;")
    s = s.replace("            wr_base <= 19'd0;", "            wr_base <= 20'd0;")
    s = s.replace("            tgt <= 9'd0;", "            tgt <= 10'd0;")
    s = s.replace("            mem_addr_u <= 19'd0;", "            mem_addr_u <= 20'd0;")
    s = s.replace("{buf_b[5][6:4], buf_b[4], buf_b[3]}", "{buf_b[5][7:4], buf_b[4], buf_b[3]}")
    s = s.replace("                                    tgt <= {buf_b[4][4], buf_b[3]};",
                  "                                    tgt <= {buf_b[4][5:4], buf_b[3]};")
    s = s.replace("                                    ctx_idx <= buf_b[3][5:0];",
                  "                                    ctx_idx <= buf_b[3][6:0];")
    s = s.replace("                                    ctx_n <= buf_b[4][5:0];",
                  "                                    ctx_n <= buf_b[4][6:0];")
    s = s.replace("tx_frame[11] <= {7'd0, pred[8]};", "tx_frame[11] <= {6'd0, pred[9:8]};")
    s = s.replace("tx_frame[5] <= {7'd0, pred[8]};", "tx_frame[5] <= {6'd0, pred[9:8]};")
    s = s.replace("^ {7'd0, pred[8]};", "^ {6'd0, pred[9:8]};")
    return s


def xf_py(src: str) -> str:
    s = src
    s = s.replace("A7-LM-05 fixed-point", "A7-LM-06 fixed-point")
    s = s.replace("lm05-signsgd-v1", "lm06-signsgd-v1")
    s = s.replace("Geometry only: V=512 C=64 d=96 L=4 H=4 d_ff=192.",
                  "Geometry only: V=1024 C=128 d=128 L=4 H=4 d_ff=256.")
    s = s.replace("V = 512\nD = 96\nC = 64\nH = 4\nL = 4\nFF = 192",
                  "V = 1024\nD = 128\nC = 128\nH = 4\nL = 4\nFF = 256")
    s = s.replace("assert PARAM_COUNT == 399360", "assert PARAM_COUNT == 802816")
    s = s.replace("assert WMEM_WORDS == 399360", "assert WMEM_WORDS == 802816")
    s = s.replace("assert OFF_POS == 49152", "assert OFF_POS == 131072")
    s = s.replace("assert OFF_L0 == 55296", "assert OFF_L0 == 147456")
    s = s.replace("assert LAYER_WORDS == 73728", "assert LAYER_WORDS == 131072")
    s = s.replace("assert OFF_HEAD == 350208", "assert OFF_HEAD == 671744")
    s = s.replace("class TinyGPT399k", "class TinyGPT803k")
    s = s.replace("TinyGPT399k", "TinyGPT803k")
    return s


def main() -> None:
    core = xf_core((ROOT / "rtl/lm/tiny_gpt399k_core.sv").read_text(encoding="utf-8"))
    (ROOT / "rtl/lm/tiny_gpt803k_core.sv").write_text(core, encoding="utf-8")
    pers = xf_persist((ROOT / "rtl/lm/lm05_persist.sv").read_text(encoding="utf-8"))
    (ROOT / "rtl/lm/lm06_persist.sv").write_text(pers, encoding="utf-8")
    top = xf_top((ROOT / "rtl/board/arty_a7_lm05_top.sv").read_text(encoding="utf-8"))
    (ROOT / "rtl/board/arty_a7_lm06_top.sv").write_text(top, encoding="utf-8")
    py = xf_py((ROOT / "python/ref/a7lm05_fixed_ref.py").read_text(encoding="utf-8"))
    (ROOT / "python/ref/a7lm06_fixed_ref.py").write_text(py, encoding="utf-8")
    print("generated core persist top python")


if __name__ == "__main__":
    main()
