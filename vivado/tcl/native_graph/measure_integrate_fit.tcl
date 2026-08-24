# integrate_fit measure — banks+16PE graph only (NO LM/01R/02M frozen glue)
# Owned path: vivado/tcl/native_graph/. New bit path only; never overwrite frozen SHAs.
# HS-11: archive measured bank util + composition budget; FAIL if V1 sum > 135 BRAM.

set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../../..]]
set build_dir  [file join $root_dir build vivado_a7ng_fit]
set out_dir    [file join $root_dir build out]
set rpt_dir    [file join $root_dir results A7-NATIVE-GRAPH INTEGRATE]
file mkdir $build_dir
file mkdir $out_dir
file mkdir $rpt_dir

set part_name xc7a100tcsg324-1
set bitfile [file join $out_dir arty_a7_ng_integrate_fit_banks.bit]
set gen_top [file join $build_dir a7ng_fit_banks_top.sv]

# Generated measure top (build/ only — not frozen rtl/)
set fh [open $gen_top w]
puts $fh {`timescale 1ns / 1ps
// AUTOGEN measure top for integrate_fit — episode+index banks + 16-lane scorer
module a7ng_fit_banks_top (
  input  logic       CLK100MHZ,
  input  logic [3:0] sw,
  input  logic [3:0] btn,
  output logic [3:0] led
);
  import a7ng_pkg::*;
  logic rst_n;
  assign rst_n = ~btn[0];
  logic [NG_LANES-1:0] lv;
  node_id_t cid [NG_LANES];
  score_terms_t terms [NG_LANES];
  score_t scores [NG_LANES];
  logic [7:0] tick;
  always_ff @(posedge CLK100MHZ or negedge rst_n) begin
    if (!rst_n) tick <= 0;
    else tick <= tick + 1;
  end
  assign lv = (tick[3:0] == 0) ? {NG_LANES{1'b1}} : '0;
  genvar gi;
  generate
    for (gi = 0; gi < NG_LANES; gi++) begin : g
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
    .m_axi_rid(4'd0), .m_axi_rdata(128'd0), .m_axi_rresp(2'b00), .m_axi_rlast(1'b0), .m_axi_rvalid(1'b0), .m_axi_rready()
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
    .m_axi_rid(4'd0), .m_axi_rdata(128'd0), .m_axi_rresp(2'b00), .m_axi_rlast(1'b0), .m_axi_rvalid(1'b0), .m_axi_rready()
  );
  assign led = {scores[0][3:0]} ^ ed[3:0] ^ ix[3:0];
endmodule
}
close $fh

create_project -force a7ng_fit $build_dir -part $part_name
set_property target_language Verilog [current_project]
add_files -norecurse [list \
    [file join $root_dir rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_lane.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_array.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_episode_bank.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_index_bank.sv] \
    $gen_top]
add_files -fileset constrs_1 -norecurse [file join $root_dir constraints a7ng02.xdc]
set_property top a7ng_fit_banks_top [current_fileset]
update_compile_order -fileset sources_1

synth_design -top a7ng_fit_banks_top -part $part_name
opt_design
place_design
route_design

report_timing_summary -file [file join $rpt_dir fit_banks_timing.rpt]
report_utilization -file [file join $rpt_dir fit_banks_util.rpt]

set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
set tns 0.0
set whs [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -hold]]
foreach p [get_timing_paths -max_paths 1000 -nworst 1 -setup -filter {SLACK < 0}] {
  set tns [expr {$tns + [get_property SLACK $p]}]
}
set lut [llength [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ CLEL* || PRIMITIVE_TYPE =~ CLE_*.*.LUT*}]]
# Prefer report numbers via utilization properties when available
set bram_tiles 0
if {[llength [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ BLOCKRAM.*.*}]] > 0} {
  set bram_tiles [llength [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ BLOCKRAM.*.*}]]
}
# Count RAMB36/RAMB18 tiles properly
set r36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set r18 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB18*}]]
set bram_tiles [expr {$r36 + ($r18 / 2.0)}]

set pe_count [llength [get_cells -quiet -hierarchical -filter {NAME =~ *u_lane*}]]
if {$pe_count == 0} {
  set pe_count [llength [get_cells -quiet -hierarchical -filter {NAME =~ *g_lane*}]]
}

puts "FIT_BANKS_WNS=$wns"
puts "FIT_BANKS_WHS=$whs"
puts "FIT_BANKS_BRAM_R36=$r36"
puts "FIT_BANKS_BRAM_R18=$r18"
puts "FIT_BANKS_BRAM_TILES=$bram_tiles"
puts "FIT_BANKS_PE=$pe_count"

if {$wns < 0} {
  puts stderr "ERROR: banks-only WNS < 0"
  exit 5
}

write_bitstream -force $bitfile
puts "FIT_BANKS_BIT=$bitfile"
puts "A7NG_INTEGRATE_FIT_BANKS_DONE"
