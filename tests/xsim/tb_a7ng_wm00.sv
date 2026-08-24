// tb_a7ng_wm00.sv — A7-BRAM-WM-00 query/seed bags (no LM-06)
// UNKNOWN: can 256/64/Top-8/32/16PE/synth DDR WM meet lossless+measurable util without LM?
// H_CANDIDATE: shared BRAM WM correct/lossless/bankable without LM (spec §33)
// H_RIVAL: silent overwrite / dual owner / BRAM>headroom without LM
// FALSIFIER: DROP>0 on capacity bags; dual-write accepted; LM SHA touched (host)
// UNIT: query/seed WM bag — not cycles-as-queries
`timescale 1ns / 1ps

module tb_a7ng_wm00;
  localparam int N_PE = 16;
  localparam int K = 8;

  logic clk, rst_n;
  logic [15:0] qep;
  logic ptr_inv;
  logic g_req, lm_req, rst_req;
  logic fill_req;
  logic [31:0] fill_id;
  logic cand_push;
  logic [31:0] cand_parent;
  logic [15:0] cand_rel;
  logic signed [15:0] cand_score;
  logic [15:0] cand_pe;
  logic [7:0] cand_agent;
  logic fr_push, fr_pop;
  logic [31:0] fr_node, fr_parent;
  logic [7:0] fr_depth, fr_agent;
  logic signed [15:0] fr_score;
  logic [15:0] fr_conf, fr_pe;
  logic [2:0] fr_status;
  logic ev_ins, ev_clr;
  logic [31:0] ev_node, ev_subj, ev_obj, ev_ep;
  logic [15:0] ev_rel, ev_conf;
  logic signed [15:0] ev_score;
  logic [7:0] ev_depth;
  logic learn_push, learn_drain;
  logic [31:0] learn_subj, learn_obj;
  logic [15:0] learn_rel, learn_evid, learn_conf;
  logic signed [15:0] learn_delta;
  logic signed [7:0] learn_reward;
  logic [N_PE-1:0] pe_req;

  logic write_gate;
  logic [1:0] owner;
  logic dual_err;
  logic [31:0] dual_cnt;
  logic lm_grant;
  logic [15:0] cand_cnt, cand_auth;
  logic [31:0] cand_drop;
  logic cand_ready;
  logic [15:0] fr_cnt;
  logic [31:0] fr_drop;
  logic ev_ready;
  logic [K-1:0] ev_mask;
  logic [31:0] ev_nodes [K];
  logic signed [15:0] ev_scores [K];
  logic [15:0] ev_cnt;
  logic [15:0] learn_cnt, learn_dirty;
  logic [31:0] learn_drop, learn_coal;
  logic learn_dv;
  logic [N_PE-1:0] pe_grant, pe_valid;
  logic [31:0] pe_busy [N_PE];
  logic [31:0] pe_grants, pe_cycles;
  logic [15:0] pe_active;
  logic [31:0] ddr_rdb, ddr_wrb, ddr_rdc, ddr_wrc;
  logic n_valid;
  logic [127:0] n_beat;
  logic [31:0] last_id, last_cue;

  int fails;
  int bag_fail;

  a7ng_wm00_top dut (
    .clk(clk), .rst_n(rst_n),
    .query_epoch_i(qep), .ptr_invalidate_i(ptr_inv),
    .graph_wr_req_i(g_req), .lm_wr_req_i(lm_req), .reset_wr_req_i(rst_req),
    .fill_node_req_i(fill_req), .fill_node_id_i(fill_id),
    .cand_push_i(cand_push), .cand_parent_i(cand_parent), .cand_rel_i(cand_rel),
    .cand_score_i(cand_score), .cand_path_epoch_i(cand_pe), .cand_agent_i(cand_agent),
    .fr_push_i(fr_push), .fr_node_i(fr_node), .fr_parent_i(fr_parent),
    .fr_depth_i(fr_depth), .fr_score_i(fr_score), .fr_conf_i(fr_conf),
    .fr_status_i(fr_status), .fr_path_epoch_i(fr_pe), .fr_agent_i(fr_agent),
    .fr_pop_i(fr_pop),
    .ev_insert_i(ev_ins), .ev_node_i(ev_node), .ev_subj_i(ev_subj),
    .ev_rel_i(ev_rel), .ev_obj_i(ev_obj), .ev_ep_i(ev_ep),
    .ev_score_i(ev_score), .ev_conf_i(ev_conf), .ev_depth_i(ev_depth),
    .ev_clear_i(ev_clr),
    .learn_push_i(learn_push), .learn_subj_i(learn_subj), .learn_rel_i(learn_rel),
    .learn_obj_i(learn_obj), .learn_delta_i(learn_delta), .learn_evid_i(learn_evid),
    .learn_reward_i(learn_reward), .learn_conf_i(learn_conf), .learn_drain_i(learn_drain),
    .pe_req_i(pe_req),
    .write_gate_o(write_gate),
    .owner_o(owner), .dual_owner_err_o(dual_err), .dual_owner_count_o(dual_cnt),
    .lm_grant_o(lm_grant),
    .cand_count_o(cand_cnt), .cand_auth_o(cand_auth), .cand_drop_o(cand_drop),
    .cand_ready_o(cand_ready),
    .fr_count_o(fr_cnt), .fr_drop_o(fr_drop),
    .ev_ready_o(ev_ready),
    .ev_valid_mask_o(ev_mask), .ev_node_o(ev_nodes), .ev_score_o(ev_scores),
    .ev_count_o(ev_cnt),
    .learn_count_o(learn_cnt), .learn_dirty_o(learn_dirty),
    .learn_drop_o(learn_drop), .learn_coal_o(learn_coal),
    .learn_drain_valid_o(learn_dv),
    .pe_grant_o(pe_grant), .pe_valid_o(pe_valid),
    .pe_busy_acc_o(pe_busy), .pe_grant_count_o(pe_grants),
    .pe_cycles_o(pe_cycles), .pe_active_o(pe_active),
    .ddr_rd_bytes_o(ddr_rdb), .ddr_wr_bytes_o(ddr_wrb),
    .ddr_rd_count_o(ddr_rdc), .ddr_wr_count_o(ddr_wrc),
    .node_beat_valid_o(n_valid), .node_beat_o(n_beat),
    .last_node_id_o(last_id), .last_node_cue_o(last_cue)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic idle_inputs;
    begin
      ptr_inv = 1'b0;
      g_req = 1'b0; lm_req = 1'b0; rst_req = 1'b0;
      fill_req = 1'b0; fill_id = '0;
      cand_push = 1'b0; cand_parent = '0; cand_rel = '0;
      cand_score = '0; cand_pe = '0; cand_agent = '0;
      fr_push = 1'b0; fr_pop = 1'b0;
      fr_node = '0; fr_parent = '0; fr_depth = '0; fr_score = '0;
      fr_conf = '0; fr_status = '0; fr_pe = '0; fr_agent = '0;
      ev_ins = 1'b0; ev_clr = 1'b0;
      ev_node = '0; ev_subj = '0; ev_rel = '0; ev_obj = '0; ev_ep = '0;
      ev_score = '0; ev_conf = '0; ev_depth = '0;
      learn_push = 1'b0; learn_drain = 1'b0;
      learn_subj = '0; learn_rel = '0; learn_obj = '0; learn_delta = '0;
      learn_evid = '0; learn_reward = '0; learn_conf = '0;
      pe_req = '0;
    end
  endtask

  task automatic claim_graph;
    begin
      @(negedge clk);
      g_req = 1'b1; lm_req = 1'b0; rst_req = 1'b0;
      @(posedge clk);
    end
  endtask

  // Fetch node from synth DDR then push into candidate WM
  task automatic fetch_push_cand(input int nid, input logic signed [15:0] sc);
    begin
      @(negedge clk);
      fill_req = 1'b1;
      fill_id  = 32'(nid);
      cand_push = 1'b0;
      @(posedge clk);
      @(negedge clk);
      fill_req = 1'b0;
      // latch committed; push
      cand_push = 1'b1;
      cand_parent = 32'hF000_0000;
      cand_rel = 16'd1;
      cand_score = sc;
      cand_pe = 16'd1;
      cand_agent = 8'(nid[3:0]);
      @(posedge clk);
      @(negedge clk);
      cand_push = 1'b0;
    end
  endtask

  // -------- BAG 1: fill 256 candidates, DROP=0 --------
  task automatic bag_fill256;
    logic [31:0] drop0;
    begin
      bag_fail = 0;
      $display("BAG FILL256 start");
      drop0 = cand_drop;
      claim_graph;
      for (int i = 0; i < 256; i++)
        fetch_push_cand(i, 16'(i));
      @(posedge clk);
      if (cand_cnt != 16'd256) begin
        $display("FAIL FILL256 count=%0d", cand_cnt);
        bag_fail++;
      end
      if (cand_drop != drop0) begin
        $display("FAIL FILL256 DROP=%0d (silent or unexpected)", cand_drop - drop0);
        bag_fail++;
      end
      if (ddr_rdc < 32'd256) begin
        $display("FAIL FILL256 ddr_rd_count=%0d", ddr_rdc);
        bag_fail++;
      end
      if (ddr_rdb < 32'(256 * 16)) begin
        $display("FAIL FILL256 ddr_rd_bytes=%0d", ddr_rdb);
        bag_fail++;
      end
      // schema version nibble in beat
      if (last_id > 32'd255) begin
        $display("FAIL FILL256 last_id=%0h", last_id);
        bag_fail++;
      end
      if (bag_fail == 0)
        $display("BAG FILL256 PASS count=%0d drop=%0d ddr_bytes=%0d", cand_cnt, cand_drop, ddr_rdb);
      else begin
        $display("BAG FILL256 FAIL fails=%0d", bag_fail);
        fails += bag_fail;
      end
    end
  endtask

  // -------- BAG 2: 257th push → DROP increments, count stays 256 --------
  task automatic bag_overflow;
    logic [31:0] d0;
    begin
      bag_fail = 0;
      $display("BAG OVERFLOW start");
      d0 = cand_drop;
      claim_graph;
      fetch_push_cand(0, 16'sd1);
      @(posedge clk);
      if (cand_cnt != 16'd256) begin
        $display("FAIL OVERFLOW count changed to %0d", cand_cnt);
        bag_fail++;
      end
      if (cand_drop != d0 + 32'd1) begin
        $display("FAIL OVERFLOW drop=%0d want %0d (silent overwrite?)", cand_drop, d0 + 1);
        bag_fail++;
      end
      if (bag_fail == 0)
        $display("BAG OVERFLOW PASS drop=%0d (not silent)", cand_drop);
      else begin
        $display("BAG OVERFLOW FAIL");
        fails += bag_fail;
      end
    end
  endtask

  // -------- BAG 3: frontier 64 + DROP on 65 --------
  task automatic bag_frontier;
    logic [31:0] d0;
    begin
      bag_fail = 0;
      $display("BAG FRONTIER start");
      claim_graph;
      for (int i = 0; i < 64; i++) begin
        @(negedge clk);
        fr_push = 1'b1;
        fr_node = 32'(i);
        fr_parent = 32'd0;
        fr_depth = 8'(i[7:0]);
        fr_score = 16'(i);
        fr_conf = 16'h0100;
        fr_status = 3'd0;
        fr_pe = 16'd1;
        fr_agent = 8'(i[7:0]);
        @(posedge clk);
      end
      @(negedge clk); fr_push = 1'b0;
      @(posedge clk);
      if (fr_cnt != 16'd64) begin
        $display("FAIL FRONTIER count=%0d", fr_cnt);
        bag_fail++;
      end
      d0 = fr_drop;
      @(negedge clk);
      fr_push = 1'b1; fr_node = 32'd99;
      @(posedge clk);
      @(negedge clk); fr_push = 1'b0;
      @(posedge clk);
      if (fr_drop != d0 + 1) begin
        $display("FAIL FRONTIER drop=%0d", fr_drop);
        bag_fail++;
      end
      if (fr_cnt != 16'd64) begin
        $display("FAIL FRONTIER count after overflow=%0d", fr_cnt);
        bag_fail++;
      end
      if (bag_fail == 0)
        $display("BAG FRONTIER PASS count=64 drop=%0d", fr_drop);
      else begin
        $display("BAG FRONTIER FAIL");
        fails += bag_fail;
      end
    end
  endtask

  // -------- BAG 4: Top-8 exact --------
  // DUT Top-8 insert is systolic (ready handshake); wait ready between inserts.
  task automatic bag_top8;
    // Insert scores: node i with score = i for i=0..31 → Top-8 = 31..24
    begin
      bag_fail = 0;
      $display("BAG TOP8 start");
      claim_graph;
      @(negedge clk); ev_clr = 1'b1; @(posedge clk);
      @(negedge clk); ev_clr = 1'b0;
      for (int i = 0; i < 32; i++) begin
        while (!ev_ready) @(posedge clk);
        @(negedge clk);
        ev_ins = 1'b1;
        ev_node = 32'(i);
        ev_subj = 32'(i);
        ev_rel = 16'd1;
        ev_obj = 32'(i + 1);
        ev_ep = 32'(i);
        ev_score = 16'(i);
        ev_conf = 16'h0200;
        ev_depth = 8'd1;
        @(posedge clk);
        @(negedge clk); ev_ins = 1'b0;
      end
      while (!ev_ready) @(posedge clk);
      repeat (2) @(posedge clk);
      if (ev_cnt != 16'd8) begin
        $display("FAIL TOP8 count=%0d", ev_cnt);
        bag_fail++;
      end
      for (int r = 0; r < 8; r++) begin
        if (!ev_mask[r]) begin
          $display("FAIL TOP8 mask[%0d]=0", r);
          bag_fail++;
        end
        if (ev_nodes[r] != 32'(31 - r)) begin
          $display("FAIL TOP8 node[%0d]=%0d want %0d", r, ev_nodes[r], 31 - r);
          bag_fail++;
        end
        if (ev_scores[r] != 16'(31 - r)) begin
          $display("FAIL TOP8 score[%0d]=%0d", r, ev_scores[r]);
          bag_fail++;
        end
      end
      if (bag_fail == 0)
        $display("BAG TOP8 PASS nodes=31..24");
      else begin
        $display("BAG TOP8 FAIL");
        fails += bag_fail;
      end
    end
  endtask

  // -------- BAG 5: learn 32 + coalesce + drain writeback --------
  task automatic bag_learn;
    logic [31:0] wr0, coal0;
    begin
      bag_fail = 0;
      $display("BAG LEARN start");
      claim_graph;
      coal0 = learn_coal;
      for (int i = 0; i < 32; i++) begin
        @(negedge clk);
        learn_push = 1'b1;
        learn_subj = 32'(i);
        learn_rel = 16'd1;
        learn_obj = 32'(i + 10);
        learn_delta = 16'sd3;
        learn_evid = 16'd1;
        learn_reward = 8'sd0;
        learn_conf = 16'h0100;
        @(posedge clk);
      end
      // coalesce hit on subject 0
      @(negedge clk);
      learn_push = 1'b1;
      learn_subj = 32'd0; learn_rel = 16'd1; learn_obj = 32'd10;
      learn_delta = 16'sd2; learn_evid = 16'd1;
      @(posedge clk);
      @(negedge clk); learn_push = 1'b0;
      @(posedge clk);
      if (learn_cnt != 16'd32) begin
        $display("FAIL LEARN count=%0d", learn_cnt);
        bag_fail++;
      end
      if (learn_coal != coal0 + 1) begin
        $display("FAIL LEARN coalesce=%0d", learn_coal);
        bag_fail++;
      end
      wr0 = ddr_wrc;
      for (int i = 0; i < 32; i++) begin
        @(negedge clk); learn_drain = 1'b1;
        @(posedge clk);
        @(negedge clk); learn_drain = 1'b0;
        @(posedge clk);
      end
      if (ddr_wrc < wr0 + 32'd1) begin
        $display("FAIL LEARN no DDR writeback wrc=%0d", ddr_wrc);
        bag_fail++;
      end
      if (bag_fail == 0)
        $display("BAG LEARN PASS count=32 coal=%0d wr=%0d bytes=%0d",
                 learn_coal, ddr_wrc, ddr_wrb);
      else begin
        $display("BAG LEARN FAIL");
        fails += bag_fail;
      end
    end
  endtask

  // -------- BAG 6: 16 PE util (fresh small cand set) --------
  task automatic bag_16pe;
    begin
      bag_fail = 0;
      $display("BAG 16PE start");
      // new query bag: invalidate + refill 16 cands
      @(negedge clk);
      ptr_inv = 1'b1; qep = qep + 16'd1;
      @(posedge clk);
      @(negedge clk); ptr_inv = 1'b0;
      claim_graph;
      for (int i = 0; i < 16; i++)
        fetch_push_cand(i, 16'(100 + i));
      @(posedge clk);
      if (cand_cnt != 16'd16) begin
        $display("FAIL 16PE cand=%0d", cand_cnt);
        bag_fail++;
      end
      // all PEs request
      @(negedge clk);
      pe_req = {N_PE{1'b1}};
      // allow pops/grants
      repeat (64) @(posedge clk);
      if (pe_grants < 32'd16) begin
        $display("FAIL 16PE grants=%0d", pe_grants);
        bag_fail++;
      end
      begin
        int busy_nz;
        busy_nz = 0;
        for (int i = 0; i < N_PE; i++)
          if (pe_busy[i] > 0) busy_nz++;
        if (busy_nz < 16) begin
          $display("FAIL 16PE busy_lanes=%0d", busy_nz);
          bag_fail++;
        end
      end
      if (lm_grant != 1'b0) begin
        $display("FAIL 16PE lm_grant asserted");
        bag_fail++;
      end
      @(negedge clk); pe_req = '0;
      if (bag_fail == 0)
        $display("BAG 16PE PASS grants=%0d cycles=%0d active_max_tracked",
                 pe_grants, pe_cycles);
      else begin
        $display("BAG 16PE FAIL");
        fails += bag_fail;
      end
    end
  endtask

  // -------- BAG 7: dual owner → error --------
  task automatic bag_dual;
    begin
      bag_fail = 0;
      $display("BAG DUAL_OWNER start");
      @(negedge clk);
      g_req = 1'b1; lm_req = 1'b1; rst_req = 1'b0;
      @(posedge clk);
      @(posedge clk);
      if (!dual_err) begin
        $display("FAIL DUAL_OWNER err not sticky");
        bag_fail++;
      end
      if (dual_cnt == 0) begin
        $display("FAIL DUAL_OWNER count=0");
        bag_fail++;
      end
      if (lm_grant) begin
        $display("FAIL DUAL_OWNER lm granted");
        bag_fail++;
      end
      @(negedge clk); g_req = 1'b0; lm_req = 1'b0;
      if (bag_fail == 0)
        $display("BAG DUAL_OWNER PASS dual_cnt=%0d", dual_cnt);
      else begin
        $display("BAG DUAL_OWNER FAIL");
        fails += bag_fail;
      end
    end
  endtask

  // -------- BAG 8: schema version on node beat --------
  task automatic bag_schema;
    begin
      bag_fail = 0;
      $display("BAG SCHEMA start");
      claim_graph;
      @(negedge clk);
      fill_req = 1'b1; fill_id = 32'd3;
      @(posedge clk); // DDR schedules valid
      begin : wait_valid
        int g;
        g = 0;
        while (!n_valid && g < 8) begin
          @(posedge clk);
          g = g + 1;
        end
        if (!n_valid) begin
          $display("FAIL SCHEMA no n_valid");
          bag_fail++;
        end else begin
          #1;
          if (n_beat[127:120] != 8'd1) begin
            $display("FAIL SCHEMA version=%0d", n_beat[127:120]);
            bag_fail++;
          end
          if (n_beat[31:0] != 32'd3) begin
            $display("FAIL SCHEMA node_id=%0d", n_beat[31:0]);
            bag_fail++;
          end
        end
      end
      @(posedge clk); // allow latch
      @(negedge clk); fill_req = 1'b0;
      @(posedge clk);
      if (last_id != 32'd3) begin
        $display("FAIL SCHEMA last_id=%0d", last_id);
        bag_fail++;
      end
      if (last_cue != (32'hC0E0_0000 + 32'd3)) begin
        $display("FAIL SCHEMA cue=%0h", last_cue);
        bag_fail++;
      end
      if (bag_fail == 0)
        $display("BAG SCHEMA PASS NodeRecordV1 version=1 id/cue match");
      else begin
        $display("BAG SCHEMA FAIL");
        fails += bag_fail;
      end
    end
  endtask

  initial begin
    fails = 0;
    idle_inputs();
    qep = 16'd1;
    rst_n = 1'b0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    bag_fill256();
    bag_overflow();
    bag_frontier();
    bag_top8();
    bag_learn();
    bag_16pe();
    bag_dual();
    bag_schema();

    $display("METRICS cand_drop=%0d fr_drop=%0d learn_drop=%0d dual=%0d",
             cand_drop, fr_drop, learn_drop, dual_cnt);
    $display("METRICS ddr_rd_bytes=%0d ddr_wr_bytes=%0d pe_grants=%0d",
             ddr_rdb, ddr_wrb, pe_grants);
    $display("METRICS lm_grant=%0d (must be 0)", lm_grant);

    if (fails == 0 && lm_grant == 1'b0) begin
      $display("A7NG_BRAM_WM00_XSIM_PASS");
      $finish(0);
    end else begin
      $display("A7NG_BRAM_WM00_XSIM_FAIL fails=%0d", fails);
      $finish(1);
    end
  end
endmodule
