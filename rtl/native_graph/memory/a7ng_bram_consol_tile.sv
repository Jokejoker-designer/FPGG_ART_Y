`timescale 1ns / 1ps
// a7ng_bram_consol_tile.sv — one forced RAMB36E1 tile for BRAM consolidate measure
// Gate: bram_consolidate. Does not touch frozen LM-06 / Digilent mig.prj.
(* keep_hierarchy = "yes" *)
module a7ng_bram_consol_tile (
  input  logic        clk,
  input  logic        en,
  input  logic        we,
  input  logic [9:0]  addr,
  input  logic [35:0] din,
  output logic [35:0] dout
);
  logic [31:0] do_a;
  logic [3:0]  dop_a;
  assign dout = {dop_a, do_a};
  (* DONT_TOUCH = "true" *)
  RAMB36E1 #(
    .DOA_REG(0),
    .DOB_REG(0),
    .EN_ECC_READ("FALSE"),
    .EN_ECC_WRITE("FALSE"),
    .RAM_EXTENSION_A("NONE"),
    .RAM_EXTENSION_B("NONE"),
    .RAM_MODE("TDP"),
    .READ_WIDTH_A(36),
    .READ_WIDTH_B(36),
    .WRITE_WIDTH_A(36),
    .WRITE_WIDTH_B(36),
    .SIM_DEVICE("7SERIES"),
    .WRITE_MODE_A("WRITE_FIRST"),
    .WRITE_MODE_B("WRITE_FIRST")
  ) u_r36 (
    .CASCADEOUTA(),
    .CASCADEOUTB(),
    .DBITERR(),
    .DOADO(do_a),
    .DOBDO(),
    .DOPADOP(dop_a),
    .DOPBDOP(),
    .ECCPARITY(),
    .RDADDRECC(),
    .SBITERR(),
    .ADDRARDADDR({1'b1, addr, 5'b00000}),
    .ADDRBWRADDR({1'b1, 15'h0000}),
    .CASCADEINA(1'b0),
    .CASCADEINB(1'b0),
    .CLKARDCLK(clk),
    .CLKBWRCLK(clk),
    .DIADI(din[31:0]),
    .DIBDI(32'h0),
    .DIPADIP(din[35:32]),
    .DIPBDIP(4'h0),
    .ENARDEN(en),
    .ENBWREN(1'b0),
    .INJECTDBITERR(1'b0),
    .INJECTSBITERR(1'b0),
    .REGCEAREGCE(1'b0),
    .REGCEB(1'b0),
    .RSTRAMARSTRAM(1'b0),
    .RSTRAMB(1'b0),
    .RSTREGARSTREG(1'b0),
    .RSTREGB(1'b0),
    .WEA({4{we}}),
    .WEBWE(8'h00)
  );
endmodule
