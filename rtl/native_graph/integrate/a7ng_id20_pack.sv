// a7ng_id20_pack.sv — U4B-GLOBAL-ID-C9-WIDTH-00
// Live ID path is 20-bit (or NG_ID_W). 64-bit 8-bit-pack is diagnostic only.
// Sentinel 799999 = 20'hC34FF. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_id20_pack (
  input  a7ng_pkg::node_id_t id_i [8],
  output logic [159:0]       pack20_o,
  output logic [63:0]        pack8_diag_o,
  output logic               low8_alias_o
);
  import a7ng_pkg::*;
  integer ki;
  logic alias_any;
  always_comb begin
    pack20_o     = 160'd0;
    pack8_diag_o = 64'd0;
    alias_any    = 1'b0;
    for (ki = 0; ki < 8; ki = ki + 1) begin
      pack20_o[20*ki +: 20]   = id_i[ki][19:0];
      pack8_diag_o[8*ki +: 8] = id_i[ki][7:0];
      if (id_i[ki][19:0] != {12'd0, id_i[ki][7:0]})
        if (id_i[ki][19:8] != 12'd0)
          alias_any = alias_any; // diagnostic pack is allowed; live path is pack20
    end
    // low8_alias if any live 20-bit id would collapse to another if truncated
    low8_alias_o = 1'b0;
    for (ki = 0; ki < 8; ki = ki + 1) begin
      if (id_i[ki][19:8] != 12'd0)
        low8_alias_o = 1'b1; // truncated 8-bit would drop high bits
    end
  end
endmodule
