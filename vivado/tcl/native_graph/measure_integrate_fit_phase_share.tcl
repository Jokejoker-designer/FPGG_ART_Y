# integrate_fit RETRY — ONE UNKNOWN: u_a_phase_share
# Prove/falsify: phase-share LM act scratch (66) with graph hotset → composed BRAM <= 134,
# WNS>=0, TNS=0, NEW bit only (never overwrite frozen LM-06/01R/02M/A0.3).
#
# Proxy model (build/ autogen — not frozen rtl/, not encoder glue):
#   residual = u_w(64)+u_snap(2) = 66 always-on RAMB36
#   shared   = max(u_a, hotset)  = 66 RAMB36, time-muxed by phase bit
#   a03      = 3 RAMB36 proxy
#   banks+scorer = measured 0 BRAM (included for composition honesty)
# Expected tile math: 66+66+3 = 135. Gate wants <=134 → headroom for MIG.

set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../../..]]
set build_dir  [file join $root_dir build vivado_a7ng_fit_ps]
set out_dir    [file join $root_dir build out]
set rpt_dir    [file join $root_dir results A7-NATIVE-GRAPH INTEGRATE]
file mkdir $build_dir
file mkdir $out_dir
file mkdir $rpt_dir

set part_name xc7a100tcsg324-1
set bitfile [file join $out_dir arty_a7_ng_integrate_fit_phase_share.bit]
set gen_top [file join $build_dir a7ng_fit_phase_share_top.sv]
set gen_bram [file join $build_dir a7ng_fit_ramb36_tile.sv]

# Force one full Block RAM Tile via RAMB36E1 primitive (inferred 1024x36 still packed to RAMB18)
set fh [open $gen_bram w]
puts $fh {`timescale 1ns / 1ps
(* keep_hierarchy = "yes" *)
module a7ng_fit_ramb36_tile (
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
}
close $fh

set fh [open $gen_top w]
puts $fh {`timescale 1ns / 1ps
// AUTOGEN measure — u_a phase-share proxy vs graph hotset (integrate_fit unknown)
module a7ng_fit_phase_share_top (
  input  logic       CLK100MHZ,
  input  logic [3:0] sw,
  input  logic [3:0] btn,
  output logic [3:0] led
);
  import a7ng_pkg::*;
  logic rst_n;
  assign rst_n = ~btn[0];

  // phase=0 → shared owned by LM act path; phase=1 → graph hotset path (time-mux)
  logic phase;
  logic [7:0] tick;
  always_ff @(posedge CLK100MHZ or negedge rst_n) begin
    if (!rst_n) begin
      tick <= 8'd0;
      phase <= 1'b0;
    end else begin
      tick <= tick + 8'd1;
      if (tick == 8'hFF) phase <= ~phase;
    end
  end

  logic [9:0]  addr;
  logic [35:0] din;
  assign addr = {tick[1:0], tick, sw[0]};
  assign din  = {4'b0, tick, tick, tick, sw, btn};

  // ---- residual LM (u_w + u_snap) : 66 tiles, always present ----
  logic [35:0] res_dout [0:65];
  logic [35:0] res_xor;
  genvar ri;
  generate
    for (ri = 0; ri < 66; ri++) begin : g_res
      a7ng_fit_ramb36_tile u_res (
        .clk(CLK100MHZ), .en(1'b1), .we(~phase),
        .addr(addr ^ {1'b0, ri[8:0]}), .din(din ^ {ri[7:0], ri[7:0], ri[7:0], ri[7:0], 4'b0}),
        .dout(res_dout[ri])
      );
    end
  endgenerate
  always_comb begin
    res_xor = '0;
    for (int i = 0; i < 66; i++) res_xor ^= res_dout[i];
  end

  // ---- shared pool (u_a XOR hotset by phase) : 66 tiles ----
  logic [35:0] sh_dout [0:65];
  logic [35:0] sh_xor;
  logic sh_we;
  assign sh_we = phase ? sw[1] : sw[2]; // both phases can write; never concurrent owners
  genvar si;
  generate
    for (si = 0; si < 66; si++) begin : g_sh
      a7ng_fit_ramb36_tile u_sh (
        .clk(CLK100MHZ), .en(1'b1), .we(sh_we),
        .addr(addr ^ {1'b0, phase, si[7:0]}),
        .din(din ^ {phase, si[6:0], tick, 4'hA}),
        .dout(sh_dout[si])
      );
    end
  endgenerate
  always_comb begin
    sh_xor = '0;
    for (int i = 0; i < 66; i++) sh_xor ^= sh_dout[i];
  end

  // ---- A0.3 proxy : 3 tiles (do not instantiate frozen encoder) ----
  logic [35:0] a3_dout [0:2];
  logic [35:0] a3_xor;
  genvar ai;
  generate
    for (ai = 0; ai < 3; ai++) begin : g_a3
      a7ng_fit_ramb36_tile u_a3 (
        .clk(CLK100MHZ), .en(1'b1), .we(btn[1]),
        .addr(addr ^ {7'b0, ai[2:0]}), .din(din), .dout(a3_dout[ai])
      );
    end
  endgenerate
  always_comb begin
    a3_xor = a3_dout[0] ^ a3_dout[1] ^ a3_dout[2];
  end

  // ---- banks + 16PE scorer (prior measure: 0 BRAM) ----
  logic [NG_LANES-1:0] lv;
  node_id_t cid [NG_LANES];
  score_terms_t terms [NG_LANES];
  score_t scores [NG_LANES];
  assign lv = (tick[3:0] == 4'd0) ? {NG_LANES{1'b1}} : '0;
  genvar gi;
  generate
    for (gi = 0; gi < NG_LANES; gi++) begin : g_lane
      always_ff @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n) begin cid[gi] <= 0; terms[gi] <= '0; end
        else begin
          cid[gi] <= node_id_t'(gi + tick);
          terms[gi].entity_match <= term_t'(8'd10);
          terms[gi].intent_match <= term_t'(8'd5);
          terms[gi].relation_match <= term_t'(sw);
          terms[gi].context_match <= term_t'(8'd1);
          terms[gi].path_confidence <= term_t'(8'd1);
          terms[gi].learned_prior <= term_t'(8'd0);
          terms[gi].contradiction_penalty <= term_t'(8'd0);
        end
      end
    end
  endgenerate
  a7ng_scorer_array u_sc (
    .clk(CLK100MHZ), .rst_n(rst_n), .valid_i(lv), .cand_id_i(cid),
    .terms_i(terms), .score_o(scores), .valid_o());
  logic [127:0] ed, ix;
  a7ng_episode_bank #(.DEPTH(16)) u_ep (
    .clk(CLK100MHZ), .rst_n(rst_n),
    .wr_i(1'b0), .wr_id_i(4'd0), .wr_data_i(128'd0),
    .rd_i(1'b0), .rd_id_i(4'd0), .rd_data_o(ed),
    .flush_i(1'b0), .reload_i(1'b0), .forget_i(1'b0),
    .busy_o(), .done_o(),
    .m_axi_awid(), .m_axi_awaddr(), .m_axi_awlen(), .m_axi_awsize(), .m_axi_awburst(),
    .m_axi_awvalid(), .m_axi_awready(1'b0),
    .m_axi_wdata(), .m_axi_wstrb(), .m_axi_wlast(), .m_axi_wvalid(), .m_axi_wready(1'b0),
    .m_axi_bid(4'd0), .m_axi_bresp(2'b00), .m_axi_bvalid(1'b0), .m_axi_bready(),
    .m_axi_arid(), .m_axi_araddr(), .m_axi_arlen(), .m_axi_arsize(), .m_axi_arburst(),
    .m_axi_arvalid(), .m_axi_arready(1'b0),
    .m_axi_rid(4'd0), .m_axi_rdata(128'd0), .m_axi_rresp(2'b00), .m_axi_rlast(1'b0),
    .m_axi_rvalid(1'b0), .m_axi_rready()
  );
  a7ng_index_bank #(.DEPTH(16)) u_ix (
    .clk(CLK100MHZ), .rst_n(rst_n),
    .wr_i(1'b0), .wr_id_i(4'd0), .wr_data_i(128'd0),
    .rd_i(1'b0), .rd_id_i(4'd0), .rd_data_o(ix),
    .flush_i(1'b0), .reload_i(1'b0), .forget_i(1'b0),
    .busy_o(), .done_o(),
    .m_axi_awid(), .m_axi_awaddr(), .m_axi_awlen(), .m_axi_awsize(), .m_axi_awburst(),
    .m_axi_awvalid(), .m_axi_awready(1'b0),
    .m_axi_wdata(), .m_axi_wstrb(), .m_axi_wlast(), .m_axi_wvalid(), .m_axi_wready(1'b0),
    .m_axi_bid(4'd0), .m_axi_bresp(2'b00), .m_axi_bvalid(1'b0), .m_axi_bready(),
    .m_axi_arid(), .m_axi_araddr(), .m_axi_arlen(), .m_axi_arsize(), .m_axi_arburst(),
    .m_axi_arvalid(), .m_axi_arready(1'b0),
    .m_axi_rid(4'd0), .m_axi_rdata(128'd0), .m_axi_rresp(2'b00), .m_axi_rlast(1'b0),
    .m_axi_rvalid(1'b0), .m_axi_rready()
  );

  assign led = res_xor[3:0] ^ sh_xor[3:0] ^ a3_xor[3:0] ^ scores[0][3:0] ^ ed[3:0] ^ ix[3:0] ^ {3'b0, phase};
endmodule
}
close $fh

create_project -force a7ng_fit_ps $build_dir -part $part_name
set_property target_language Verilog [current_project]
add_files -norecurse [list \
    [file join $root_dir rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_lane.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_array.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_episode_bank.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_index_bank.sv] \
    $gen_bram \
    $gen_top]
add_files -fileset constrs_1 -norecurse [file join $root_dir constraints a7ng02.xdc]
set_property top a7ng_fit_phase_share_top [current_fileset]
update_compile_order -fileset sources_1

synth_design -top a7ng_fit_phase_share_top -part $part_name
opt_design
place_design
route_design

report_timing_summary -file [file join $rpt_dir fit_phase_share_timing.rpt]
report_utilization -file [file join $rpt_dir fit_phase_share_util.rpt]

set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
set tns 0.0
set whs [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -hold]]
set ths 0.0
foreach p [get_timing_paths -max_paths 1000 -nworst 1 -setup -filter {SLACK < 0}] {
  set tns [expr {$tns + [get_property SLACK $p]}]
}
foreach p [get_timing_paths -max_paths 1000 -nworst 1 -hold -filter {SLACK < 0}] {
  set ths [expr {$ths + [get_property SLACK $p]}]
}

set r36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set r18 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB18*}]]
set bram_tiles [expr {$r36 + ($r18 / 2.0)}]

puts "FIT_PS_WNS=$wns"
puts "FIT_PS_TNS=$tns"
puts "FIT_PS_WHS=$whs"
puts "FIT_PS_THS=$ths"
puts "FIT_PS_BRAM_R36=$r36"
puts "FIT_PS_BRAM_R18=$r18"
puts "FIT_PS_BRAM_TILES=$bram_tiles"

# Sanity: real LM-scale proxy must land on full tiles (not RAMB18 half-pack)
if {$r36 < 130} {
  puts "FIT_PS_VERDICT=FAIL"
  puts "FIT_PS_NOTE=proxy under-packed (R36=$r36); not a valid u_a phase-share proof"
} else {
  # Gate: BRAM <= 134 AND WNS>=0 AND TNS==0
  set gate_bram_ok [expr {$bram_tiles <= 134}]
  set gate_wns_ok  [expr {$wns >= 0}]
  set gate_tns_ok  [expr {abs($tns) < 1e-9}]
  if {$gate_bram_ok && $gate_wns_ok && $gate_tns_ok} {
    puts "FIT_PS_VERDICT=PASS"
  } elseif {!$gate_bram_ok && $gate_wns_ok && $gate_tns_ok} {
    puts "FIT_PS_VERDICT=LIMIT"
    puts "FIT_PS_NOTE=phase-share at full u_a capacity still BRAM=$bram_tiles (need<=134)"
  } else {
    puts "FIT_PS_VERDICT=FAIL"
  }
}

write_bitstream -force $bitfile
file copy -force $bitfile [file join $rpt_dir arty_a7_ng_integrate_fit_phase_share.bit]
puts "FIT_PS_BIT=$bitfile"
puts "A7NG_INTEGRATE_FIT_PHASE_SHARE_DONE"
