// arty_a7_ng_integrate_lite_top.sv — graph+mem banks only (no LM-06/01R/02M frozen glue)
`timescale 1ns / 1ps

module arty_a7_ng_integrate_lite_top (
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

  a7ng_scorer_array u_sc (.clk(CLK100MHZ), .rst_n(rst_n), .valid_i(lv), .cand_id_i(cid), .terms_i(terms), .score_o(scores), .valid_o());

  logic [127:0] ed;
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

  assign led = {scores[0][3:0]};
endmodule
