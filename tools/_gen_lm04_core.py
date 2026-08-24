"""One-shot generator: scale tiny_gpt25k_core.sv → tiny_gpt100k_core.sv."""
from pathlib import Path

src = Path("rtl/lm/tiny_gpt25k_core.sv").read_text(encoding="utf-8")
repls = [
    ("import a7lm03_pkg::*;", "import a7lm04_pkg::*;"),
    ("module tiny_gpt25k_core", "module tiny_gpt100k_core"),
    ("// Counters are 9-bit so V=128 and FF=64 do not wrap.",
     "// Counters are 9-bit so V=256 and FF=128 do not wrap."),
    ("input  logic [14:0]        mem_addr,", "input  logic [16:0]        mem_addr,"),
    ("input  logic [3:0]         ctx_idx,", "input  logic [4:0]         ctx_idx,"),
    ("input  logic [3:0]         ctx_n_in,", "input  logic [4:0]         ctx_n_in,"),
    ("input  logic [6:0]         tgt_in,", "input  logic [7:0]         tgt_in,"),
    ("output logic [6:0]         pred,", "output logic [7:0]         pred,"),
    ("logic [3:0] ntok, tok_i, tok_j;", "logic [4:0] ntok, tok_i, tok_j;"),
    ("logic [7:0] tok [0:15];", "logic [7:0] tok [0:31];"),
    ("logic [6:0] tgt;", "logic [7:0] tgt;"),
    ("logic [6:0] vix;", "logic [7:0] vix;"),
    ("logic signed [31:0] score [0:15];", "logic signed [31:0] score [0:31];"),
    ("logic [7:0]         exps [0:15];", "logic [7:0]         exps [0:31];"),
    ("logic [7:0]         e_last [0:1][0:15];", "logic [7:0]         e_last [0:1][0:31];"),
    ("logic [14:0]        waddr, caddr, ck_raddr;", "logic [16:0]        waddr, caddr, ck_raddr;"),
    ("logic signed [31:0] logits [0:127];", "logic signed [31:0] logits [0:255];"),
    ("logic [7:0]         smx_e [0:127];", "logic [7:0]         smx_e [0:255];"),
    ("logic [6:0]         arg_best;", "logic [7:0]         arg_best;"),
    ("logic [14:0]        wbase;", "logic [16:0]        wbase;"),
    ('(* ram_style = "registers" *) logic signed [31:0] dY [0:31];',
     '(* ram_style = "registers" *) logic signed [31:0] dY [0:63];'),
    ('(* ram_style = "registers" *) logic signed [31:0] dH [0:31];',
     '(* ram_style = "registers" *) logic signed [31:0] dH [0:63];'),
    ('(* ram_style = "registers" *) logic signed [31:0] dHid [0:63];',
     '(* ram_style = "registers" *) logic signed [31:0] dHid [0:127];'),
    ('(* ram_style = "registers" *) logic signed [31:0] n1_last [0:1][0:31];',
     '(* ram_style = "registers" *) logic signed [31:0] n1_last [0:1][0:63];'),
    ('(* ram_style = "registers" *) logic signed [31:0] a_last [0:1][0:31];',
     '(* ram_style = "registers" *) logic signed [31:0] a_last [0:1][0:63];'),
    ("logic [13:0]        aaddr, aaddr_b;", "logic [15:0]        aaddr, aaddr_b;"),
    ("weight_bram25k", "weight_bram100k"),
    ("act_ram32k", "act_ram64k"),
]
for a, b in repls:
    if a not in src:
        raise SystemExit("missing: " + repr(a[:80]))
    src = src.replace(a, b)

old_aa = """    // 16K act map, no overlap:
    //   0x0000-0x1FFF tensors {0,ly,t[2:0],tk[3:0],d[4:0]}
    //   0x2000-0x27FF hid     0x2000+{ly,tk,hh[5:0]}
    //   0x2800-0x2BFF y       0x2800+{ly,tk,d[4:0]}
    function automatic [13:0] aa(input ly_, input [2:0] t, input [3:0] tk, input [5:0] d);
        return {1'b0, ly_, t, tk, d[4:0]};
    endfunction

    function automatic [13:0] ah(input ly_, input [3:0] tk, input [5:0] hh);
        return 14'h2000 + {ly_, tk, hh[5:0]};
    endfunction

    function automatic [13:0] ay(input ly_, input [3:0] tk, input [5:0] d);
        return 14'h2800 + {ly_, tk, d[4:0]};
    endfunction

    function automatic [3:0] last_tok(input [3:0] n);
        return (n == 4'd0) ? 4'd0 : (n - 4'd1);
    endfunction"""
new_aa = """    // 64K act map, no overlap:
    //   0x0000-0x7FFF tensors {ly,t[2:0],tk[4:0],d[5:0]}
    //   0x8000-0x9FFF hid     0x8000+{ly,tk[4:0],hh[6:0]}
    //   0xA000-0xAFFF y       0xA000+{ly,tk[4:0],d[5:0]}
    function automatic [15:0] aa(input ly_, input [2:0] t, input [4:0] tk, input [5:0] d);
        return {1'b0, ly_, t, tk, d};
    endfunction

    function automatic [15:0] ah(input ly_, input [4:0] tk, input [6:0] hh);
        return 16'h8000 + {ly_, tk, hh};
    endfunction

    function automatic [15:0] ay(input ly_, input [4:0] tk, input [5:0] d);
        return 16'hA000 + {ly_, tk, d};
    endfunction

    function automatic [4:0] last_tok(input [4:0] n);
        return (n == 5'd0) ? 5'd0 : (n - 5'd1);
    endfunction"""
if old_aa not in src:
    raise SystemExit("aa block missing")
src = src.replace(old_aa, new_aa)
src = src.replace("{1'b0, hix[0], dim[3:0]}", "{hix[1:0], dim[3:0]}")
src = src.replace("pred <= 7'd0;", "pred <= 8'd0;")
src = src.replace("waddr <= 15'd0;", "waddr <= 17'd0;")
src = src.replace("caddr <= 15'd0;", "caddr <= 17'd0;")
src = src.replace("ck_raddr <= 15'd0;", "ck_raddr <= 17'd0;")
src = src.replace("15'(OFF_", "17'(OFF_")
src = src.replace("15'(tok", "17'(tok")
src = src.replace("15'(D)", "17'(D)")
src = src.replace("15'(dim)", "17'(dim)")
src = src.replace("15'(tok_i)", "17'(tok_i)")
src = src.replace("15'(LAYER_W)", "17'(LAYER_W)")
src = src.replace("15'(LO_", "17'(LO_")
src = src.replace("15'(row)", "17'(row)")
src = src.replace("15'(col)", "17'(col)")
src = src.replace("15'(vix)", "17'(vix)")
src = src.replace("15'(NPARAM)", "17'(NPARAM)")
src = src.replace("15'(wbase)", "17'(wbase)")
src = src.replace("15'(last)", "17'(last")  # may not exist
src = src.replace(
    "for (ii = 0; ii < 16; ii = ii + 1) tok[ii] <= 8'd0;",
    "for (ii = 0; ii < 32; ii = ii + 1) tok[ii] <= 8'd0;",
)
src = src.replace(
    "for (ii = 0; ii < 128; ii = ii + 1) begin",
    "for (ii = 0; ii < 256; ii = ii + 1) begin",
)
src = src.replace("if ({12'd0, ctx_idx} + ii < 16)", "if ({11'd0, ctx_idx} + ii < 32)")
src = src.replace("tok[ctx_idx + ii[3:0]]", "tok[ctx_idx + ii[4:0]]")
src = src.replace("tok_i <= 4'd0;", "tok_i <= 5'd0;")
src = src.replace("tok_j <= 4'd0;", "tok_j <= 5'd0;")
src = src.replace("tok_i + 4'd1", "tok_i + 5'd1")
src = src.replace("tok_j + 4'd1", "tok_j + 5'd1")
src = src.replace("logits[row[6:0]]", "logits[row[7:0]]")
src = src.replace("vix == 7'd0", "vix == 8'd0")
src = src.replace("vix <= 7'd0;", "vix <= 8'd0;")
src = src.replace("vix + 7'd1", "vix + 8'd1")
src = src.replace("ah(ly, tok_i, col[5:0])", "ah(ly, tok_i, {1'b0, col[5:0]})")
src = src.replace("ah(ly, tok_i, row[5:0])", "ah(ly, tok_i, {1'b0, row[5:0]})")
src = src.replace("ah(ly, last_tok(ntok), dim[5:0])", "ah(ly, last_tok(ntok), {1'b0, dim[5:0]})")
src = src.replace("ntok <= 4'd0;", "ntok <= 5'd0;")
src = src.replace("arg_best <= 7'd0;", "arg_best <= 8'd0;")
src = src.replace("mu <= sat32(acc >>> 5); // D=32", "mu <= sat32(acc >>> 6); // D=64")
src = src.replace("var_u <= acc[36:5]; // (sum sq) // 32, unsigned, may set bit31",
                  "var_u <= acc[37:6]; // (sum sq) // 64, unsigned, may set bit31")
src = src.replace("acc[36:5]", "acc[37:6]")
src = src.replace("if (tok_j == 4'd15) begin", "if (tok_j == 5'd31) begin")
src = src.replace("caddr + 15'd1", "caddr + 17'd1")
src = src.replace("tgt <= (8'd16 + (k - 8'd1));", "tgt <= (8'd32 + (k - 8'd1));")
src = src.replace("ntok <= 4'd1;", "ntok <= 5'd1;")
src = src.replace(
    """    weight_bram100k u_ckpt (
        .clk(clk), .we_a(cwe), .addr_a(caddr), .wdata_a(wrd), .rdata_a(),
        .addr_b(ck_raddr), .rdata_b(ckd)
    );""",
    "    assign ckd = 8'sd0;",
)
src = src.replace("smx_e[vix]", "smx_e[vix]")  # noop keep
out = Path("rtl/lm/tiny_gpt100k_core.sv")
out.write_text(src, encoding="utf-8")
print("wrote", out, "lines", len(src.splitlines()))
