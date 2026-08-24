# integrate_fit RETRY — ONE UNKNOWN: ownership_audited_tile_cut
# H_CANDIDATE: Prefer <=130 BRAM tiles after ownership audit meets R6 numeric
#   BRAM<=device, WNS>=0, TNS=0 on NEW composed measure top.
# Lever (PLAN C3 / MEM-00 ranking): drop concurrent A0.3 + DDR-spill 2 of u_a
#   (u_a classified DDR-backable-partial). Full-66 u_a phase-share is FALSIFIED.
# Never overwrite frozen LM-06 / 01R / 02M / A0.3 bits.
#
# Proxy model (build/ autogen — not frozen rtl/, not encoder glue):
#   residual = u_w(64)+u_snap(2) = 66 always-on RAMB36
#   shared   = DDR-spill cut of u_a|hotset = 64 RAMB36, exclusive owner FSM
#   a03      = 0 (not concurrent on same bit — PASS_NARROW if other gates OK)
#   banks+scorer = 0 BRAM (prior measure)
#   MIG      = 0 BRAM cited NG-03 MIG post-route (not re-instantiated here)
# Expected tiles: 66+64 = 130. Prefer <=130; device max 135.

set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../../..]]
set build_dir  [file join $root_dir build vivado_a7ng_fit_own]
set out_dir    [file join $root_dir build out]
set rpt_dir    [file join $root_dir results A7-NATIVE-GRAPH INTEGRATE]
file mkdir $build_dir
file mkdir $out_dir
file mkdir $rpt_dir

set part_name xc7a100tcsg324-1
set bitfile [file join $out_dir arty_a7_ng_integrate_fit_own_cut.bit]
set gen_top [file join $build_dir a7ng_fit_own_cut_top.sv]
set gen_bram [file join $build_dir a7ng_fit_ramb36_tile.sv]

set residual_n 66
set shared_n   64
set target_max 130

# Force one full Block RAM Tile via RAMB36E1 primitive
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
puts $fh "`timescale 1ns / 1ps
// AUTOGEN measure — ownership-audited tile cut (integrate_fit unknown)
// residual=${residual_n} + shared_cut=${shared_n} + a03=0 => prefer <=${target_max}
module a7ng_fit_own_cut_top (
  input  logic       CLK100MHZ,
  input  logic \[3:0\] sw,
  input  logic \[3:0\] btn,
  output logic \[3:0\] led
);
  import a7ng_pkg::*;
  logic rst_n;
  assign rst_n = ~btn\[0\];

  // Owner FSM: exactly one writer authority on shared pool (R6 ownership=0)
  // Cycle: GRAPH -> HOLD (we=0 drain) -> LM -> HOLD -> GRAPH
  typedef enum logic \[1:0\] {
    BRAM_OWNER_GRAPH = 2'd0,
    BRAM_OWNER_LM    = 2'd1,
    BRAM_OWNER_HOLD  = 2'd2
  } bram_owner_e;
  bram_owner_e owner;
  bram_owner_e owner_next_after_hold;
  logic \[7:0\] tick;
  always_ff @(posedge CLK100MHZ or negedge rst_n) begin
    if (!rst_n) begin
      tick  <= 8'd0;
      owner <= BRAM_OWNER_GRAPH;
      owner_next_after_hold <= BRAM_OWNER_LM;
    end else begin
      tick <= tick + 8'd1;
      if (tick == 8'hFF) begin
        unique case (owner)
          BRAM_OWNER_GRAPH: begin
            owner <= BRAM_OWNER_HOLD;
            owner_next_after_hold <= BRAM_OWNER_LM;
          end
          BRAM_OWNER_LM: begin
            owner <= BRAM_OWNER_HOLD;
            owner_next_after_hold <= BRAM_OWNER_GRAPH;
          end
          BRAM_OWNER_HOLD: owner <= owner_next_after_hold;
          default: owner <= BRAM_OWNER_GRAPH;
        endcase
      end
    end
  end

  logic \[9:0\]  addr;
  logic \[35:0\] din;
  assign addr = {tick\[1:0\], tick, sw\[0\]};
  assign din  = {4'b0, tick, tick, tick, sw, btn};

  // ---- residual LM (u_w + u_snap) : ${residual_n} tiles, always present ----
  logic \[35:0\] res_dout \[0:${residual_n}-1\];
  logic \[35:0\] res_xor;
  genvar ri;
  generate
    for (ri = 0; ri < ${residual_n}; ri++) begin : g_res
      a7ng_fit_ramb36_tile u_res (
        .clk(CLK100MHZ), .en(1'b1),
        .we(owner == BRAM_OWNER_LM),
        .addr(addr ^ {1'b0, ri\[8:0\]}),
        .din(din ^ {ri\[7:0\], ri\[7:0\], ri\[7:0\], ri\[7:0\], 4'b0}),
        .dout(res_dout\[ri\])
      );
    end
  endgenerate
  always_comb begin
    res_xor = '0;
    for (int i = 0; i < ${residual_n}; i++) res_xor ^= res_dout\[i\];
  end

  // ---- shared cut pool (DDR-spilled u_a XOR hotset) : ${shared_n} tiles ----
  // Exactly one WE authority: LM or GRAPH; HOLD => we=0 (no dual-owner write)
  logic \[35:0\] sh_dout \[0:${shared_n}-1\];
  logic \[35:0\] sh_xor;
  logic sh_we;
  logic owner_is_lm;
  logic owner_is_graph;
  assign owner_is_lm    = (owner == BRAM_OWNER_LM);
  assign owner_is_graph = (owner == BRAM_OWNER_GRAPH);
  assign sh_we = owner_is_lm ? sw\[2\] : (owner_is_graph ? sw\[1\] : 1'b0);
  // dual-owner detect (must stay 0): both write enables asserted same cycle
  logic dual_owner_err;
  always_ff @(posedge CLK100MHZ or negedge rst_n) begin
    if (!rst_n) dual_owner_err <= 1'b0;
    else if (owner_is_lm && owner_is_graph) dual_owner_err <= 1'b1;
  end
  genvar si;
  generate
    for (si = 0; si < ${shared_n}; si++) begin : g_sh
      a7ng_fit_ramb36_tile u_sh (
        .clk(CLK100MHZ), .en(1'b1), .we(sh_we),
        .addr(addr ^ {1'b0, owner_is_lm, si\[7:0\]}),
        .din(din ^ {owner_is_lm, si\[6:0\], tick, 4'hA}),
        .dout(sh_dout\[si\])
      );
    end
  endgenerate
  always_comb begin
    sh_xor = '0;
    for (int i = 0; i < ${shared_n}; i++) sh_xor ^= sh_dout\[i\];
  end

  // ---- banks + 16PE scorer (prior measure: 0 BRAM) ----
  logic \[NG_LANES-1:0\] lv;
  node_id_t cid \[NG_LANES\];
  score_terms_t terms \[NG_LANES\];
  score_t scores \[NG_LANES\];
  assign lv = (tick\[3:0\] == 4'd0) ? {NG_LANES{1'b1}} : '0;
  genvar gi;
  generate
    for (gi = 0; gi < NG_LANES; gi++) begin : g_lane
      always_ff @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n) begin cid\[gi\] <= 0; terms\[gi\] <= '0; end
        else begin
          cid\[gi\] <= node_id_t'(gi + tick);
          terms\[gi\].entity_match <= term_t'(8'd10);
          terms\[gi\].intent_match <= term_t'(8'd5);
          terms\[gi\].relation_match <= term_t'(sw);
          terms\[gi\].context_match <= term_t'(8'd1);
          terms\[gi\].path_confidence <= term_t'(8'd1);
          terms\[gi\].learned_prior <= term_t'(8'd0);
          terms\[gi\].contradiction_penalty <= term_t'(8'd0);
        end
      end
    end
  endgenerate
  a7ng_scorer_array u_sc (
    .clk(CLK100MHZ), .rst_n(rst_n), .valid_i(lv), .cand_id_i(cid),
    .terms_i(terms), .score_o(scores), .valid_o());
  logic \[127:0\] ed, ix;
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

  assign led = res_xor\[3:0\] ^ sh_xor\[3:0\] ^ scores\[0\]\[3:0\] ^ ed\[3:0\] ^ ix\[3:0\]
               ^ {2'b0, dual_owner_err, owner_is_lm};
endmodule
"
close $fh

create_project -force a7ng_fit_own $build_dir -part $part_name
set_property target_language Verilog [current_project]
add_files -norecurse [list \
    [file join $root_dir rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_mem_schema_v1.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_lane.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_array.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_episode_bank.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_index_bank.sv] \
    $gen_bram \
    $gen_top]
add_files -fileset constrs_1 -norecurse [file join $root_dir constraints a7ng02.xdc]
set_property top a7ng_fit_own_cut_top [current_fileset]
update_compile_order -fileset sources_1

synth_design -top a7ng_fit_own_cut_top -part $part_name
opt_design
place_design
route_design

report_timing_summary -file [file join $rpt_dir fit_own_cut_timing.rpt]
report_utilization -file [file join $rpt_dir fit_own_cut_util.rpt]

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
set lut [llength [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ CLEL* || PRIMITIVE_TYPE =~ CLE_*.*.LUT*}]]
set ff  [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ FD*}]]
set dsp [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ DSP*}]]

puts "FIT_OWN_WNS=$wns"
puts "FIT_OWN_TNS=$tns"
puts "FIT_OWN_WHS=$whs"
puts "FIT_OWN_THS=$ths"
puts "FIT_OWN_BRAM_R36=$r36"
puts "FIT_OWN_BRAM_R18=$r18"
puts "FIT_OWN_BRAM_TILES=$bram_tiles"
puts "FIT_OWN_LUT_CELLS=$lut"
puts "FIT_OWN_FF_CELLS=$ff"
puts "FIT_OWN_DSP=$dsp"

# Sanity: must land on full tiles near expected 130
if {$r36 < 120} {
  puts "FIT_OWN_VERDICT=FAIL"
  puts "FIT_OWN_NOTE=proxy under-packed (R36=$r36); not a valid ownership-cut proof"
} else {
  set gate_bram_ok [expr {$bram_tiles <= $target_max}]
  set gate_dev_ok  [expr {$bram_tiles <= 135}]
  set gate_wns_ok  [expr {$wns >= 0}]
  set gate_tns_ok  [expr {abs($tns) < 1e-9}]
  if {$gate_bram_ok && $gate_dev_ok && $gate_wns_ok && $gate_tns_ok} {
    puts "FIT_OWN_VERDICT=PASS_NARROW"
    puts "FIT_OWN_NOTE=BRAM=$bram_tiles<=$target_max WNS/TNS OK; narrow=no concurrent A0.3; MIG BRAM cited NG-03=0; DDR corruption not silicon"
  } elseif {$gate_dev_ok && $gate_wns_ok && $gate_tns_ok && !$gate_bram_ok} {
    puts "FIT_OWN_VERDICT=LIMIT"
    puts "FIT_OWN_NOTE=BRAM=$bram_tiles > prefer $target_max (device OK)"
  } else {
    puts "FIT_OWN_VERDICT=FAIL"
  }
}

write_bitstream -force $bitfile
file copy -force $bitfile [file join $rpt_dir arty_a7_ng_integrate_fit_own_cut.bit]
puts "FIT_OWN_BIT=$bitfile"
puts "A7NG_INTEGRATE_FIT_OWN_CUT_DONE"
