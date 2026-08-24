"""One-shot mechanical port of tiny_gpt399k_core.sv from the 100k copy."""
from __future__ import annotations

from pathlib import Path

src = Path(__file__).resolve().parents[1] / "rtl" / "lm" / "tiny_gpt100k_core.sv"
dst = Path(__file__).resolve().parents[1] / "rtl" / "lm" / "tiny_gpt399k_core.sv"
s = src.read_text(encoding="utf-8")

blocks = [
    ("import a7lm04_pkg::*;", "import a7lm05_pkg::*;"),
    ("// Sequential 2-layer 2-head TinyGPT. law_id lm05-signsgd-v1.",
     "// Sequential 4-layer 4-head TinyGPT. law_id lm05-signsgd-v1."),
    ("// Counters are 9-bit so V=256 and FF=128 do not wrap.",
     "// Counters are 9-bit so V=512, D=96, FF=192 do not wrap."),
    ("module tiny_gpt100k_core (", "module tiny_gpt399k_core ("),
    ("    input  logic [16:0]        mem_addr,", "    input  logic [18:0]        mem_addr,"),
    ("    output logic [7:0]         pred,", "    output logic [8:0]         pred,"),
    ("    input  logic [4:0]         ctx_idx,", "    input  logic [5:0]         ctx_idx,"),
    ("    input  logic [4:0]         ctx_n_in,", "    input  logic [5:0]         ctx_n_in,"),
    ("    input  logic [7:0]         tgt_in,", "    input  logic [8:0]         tgt_in,"),
    ("    logic [4:0] ntok, tok_i, tok_j;", "    logic [5:0] ntok, tok_i, tok_j;"),
    ("    logic [7:0] tok [0:31];", "    logic [7:0] tok [0:63];"),
    ("    logic [7:0] tgt;", "    logic [8:0] tgt;"),
    ("    logic       ly;", "    logic [1:0]  ly;"),
    ("    logic signed [31:0] logits [0:255];", "    logic signed [31:0] logits [0:511];"),
    ("    logic [7:0]         smx_e [0:255];", "    logic [7:0]         smx_e [0:511];"),
    ("    logic [7:0]         arg_best;", "    logic [8:0]         arg_best;"),
    ("    logic signed [31:0] score [0:31];", "    logic signed [31:0] score [0:63];"),
    ("    logic [7:0]         exps [0:31];", "    logic [7:0]         exps [0:63];"),
    ("    logic [7:0]         e_last [0:3][0:31];", "    logic [7:0]         e_last [0:3][0:63];"),
    ('    (* ram_style = "registers" *) logic signed [31:0] dY [0:63];',
     '    (* ram_style = "registers" *) logic signed [31:0] dY [0:95];'),
    ('    (* ram_style = "registers" *) logic signed [31:0] dH [0:63];',
     '    (* ram_style = "registers" *) logic signed [31:0] dH [0:95];'),
    ('    (* ram_style = "registers" *) logic signed [31:0] dHid [0:127];',
     '    (* ram_style = "registers" *) logic signed [31:0] dHid [0:191];'),
    ('    (* ram_style = "registers" *) logic signed [31:0] n1_last [0:1][0:63];',
     '    (* ram_style = "registers" *) logic signed [31:0] n1_last [0:3][0:95];'),
    ('    (* ram_style = "registers" *) logic signed [31:0] a_last [0:1][0:63];',
     '    (* ram_style = "registers" *) logic signed [31:0] a_last [0:3][0:95];'),
    ("    logic [16:0]        waddr, caddr, ck_raddr;",
     "    logic [18:0]        waddr, caddr, ck_raddr;"),
    ("    logic [15:0]        aaddr, aaddr_b;", "    logic [17:0]        aaddr, aaddr_b;"),
    ("    logic [7:0] vix;", "    logic [8:0] vix;"),
    ("    weight_bram100k u_w (", "    weight_bram399k u_w ("),
    ("    act_ram64k u_a (", "    act_ram256k u_a ("),
]
for a, b in blocks:
    if a not in s:
        raise SystemExit("missing:\n" + a)
    s = s.replace(a, b, 1)

old_aa = """    function automatic [15:0] aa(input ly_, input [2:0] t, input [4:0] tk, input [5:0] d);
        return {1'b0, ly_, t, tk, d};
    endfunction"""
new_aa = """    function automatic [17:0] aa(input [1:0] ly_, input [2:0] t, input [5:0] tk, input [6:0] d);
        return {ly_, t, tk, d};
    endfunction"""
old_ah = """    function automatic [15:0] ah(input ly_, input [4:0] tk, input [6:0] hh);
        return 16'h8000 + {ly_, tk, hh};
    endfunction"""
new_ah = """    function automatic [17:0] ah(input [1:0] ly_, input [5:0] tk, input [7:0] hh);
        return 18'h20000 + {ly_, tk, hh};
    endfunction"""
old_ay = """    function automatic [15:0] ay(input ly_, input [4:0] tk, input [5:0] d);
        return 16'hA000 + {ly_, tk, d};
    endfunction"""
new_ay = """    function automatic [17:0] ay(input [1:0] ly_, input [5:0] tk, input [6:0] d);
        return 18'h28000 + {ly_, tk, d};
    endfunction"""
old_lt = """    function automatic [4:0] last_tok(input [4:0] n);
        return (n == 5'd0) ? 5'd0 : (n - 5'd1);
    endfunction"""
new_lt = """    function automatic [5:0] last_tok(input [5:0] n);
        return (n == 6'd0) ? 6'd0 : (n - 6'd1);
    endfunction"""
for a, b in ((old_aa, new_aa), (old_ah, new_ah), (old_ay, new_ay), (old_lt, new_lt)):
    if a not in s:
        raise SystemExit("missing fn:\n" + a)
    s = s.replace(a, b, 1)

s = s.replace("17'd0", "19'd0")
s = s.replace("17'(", "19'(")
s = s.replace("tok_i + 5'd1", "tok_i + 6'd1")
s = s.replace("tok_i <= 5'd0", "tok_i <= 6'd0")
s = s.replace("8'd255", "9'd511")
s = s.replace("vix <= 8'd0", "vix <= 9'd0")
s = s.replace("vix == 8'd0", "vix == 9'd0")
s = s.replace("arg_best <= 8'd0", "arg_best <= 9'd0")
s = s.replace("dim[5:0]", "dim[6:0]")
s = s.replace("col[5:0]", "col[6:0]")
s = s.replace("row[5:0]", "row[6:0]")
s = s.replace("dHid[col[6:0]]", "dHid[col[7:0]]")
s = s.replace("dY[dim[5:0]]", "dY[dim[6:0]]")
s = s.replace("dH[dim[5:0]]", "dH[dim[6:0]]")
s = s.replace("dY[ii]", "dY[ii]")
s = s.replace("for (ii = 0; ii < 64; ii = ii + 1)", "for (ii = 0; ii < 96; ii = ii + 1)")

# residual from previous layer y
s = s.replace("ay(1'b0, tok_i, dim[6:0])", "ay(ly - 2'd1, tok_i, dim[6:0])")
s = s.replace("aa(1'b0, 3'd0, tok_i, dim[6:0])", "aa(2'd0, 3'd0, tok_i, dim[6:0])")
s = s.replace("aa(ly, ", "aa(ly, ")
s = s.replace("ay(1'b1, last_tok(ntok), dim[6:0])", "ay(2'd3, last_tok(ntok), dim[6:0])")

# forward: after last token of residual, next layer or head
old_fwd = """                                    end else if (!ly) begin
                                        ly <= 1'b1; ten <= 3'd0; acc <= 64'sd0; st <= ST_LN_S;
                                    end else begin"""
new_fwd = """                                    end else if (ly != 2'd3) begin
                                        ly <= ly + 2'd1; ten <= 3'd0; acc <= 64'sd0; st <= ST_LN_S;
                                    end else begin"""
if old_fwd not in s:
    raise SystemExit("missing forward layer step")
s = s.replace(old_fwd, new_fwd, 1)

old_bwd = """                                        if (ly) begin
                                            ly <= 1'b0; col <= 9'd0; dim <= 9'd0; acc <= 64'sd0; st <= ST_DHID;
                                        end else begin
                                            dim <= 9'd0; sub <= 4'd0; st <= ST_BEM;
                                        end"""
new_bwd = """                                        if (ly != 2'd0) begin
                                            ly <= ly - 2'd1; col <= 9'd0; dim <= 9'd0; acc <= 64'sd0; st <= ST_DHID;
                                        end else begin
                                            dim <= 9'd0; sub <= 4'd0; st <= ST_BEM;
                                        end"""
if old_bwd not in s:
    raise SystemExit("missing backward layer step")
s = s.replace(old_bwd, new_bwd, 1)

s = s.replace("ly <= 1'b0", "ly <= 2'd0")
s = s.replace("ly <= 1'b1", "ly <= 2'd3")

dst.write_text(s, encoding="utf-8")
print("ok", dst, "lines", len(s.splitlines()))
