`timescale 1ns / 1ps
// a7ng_bram_consol_top.sv — Arty A7-100T measure top for bram_consolidate
// Shared TinyGPT-sized pool (132) = WM share of wt+act (not UA128+TinyGPT132).
module a7ng_bram_consol_top (
  input  logic       CLK100MHZ,
  input  logic [3:0] sw,
  input  logic [3:0] btn,
  output logic [3:0] led
);
  logic rst_n;
  assign rst_n = ~btn[0];

  logic [1:0] owner;
  logic       dual_err;

  a7ng_bram_consol #(.SHARED_TILES(132)) u_consol (
    .clk(CLK100MHZ),
    .rst_n(rst_n),
    .sw(sw),
    .btn(btn),
    .led(led),
    .owner_o(owner),
    .dual_owner_err_o(dual_err)
  );
endmodule
