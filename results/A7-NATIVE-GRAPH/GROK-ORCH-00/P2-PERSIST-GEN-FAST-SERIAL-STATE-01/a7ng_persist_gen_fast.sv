// a7ng_persist_gen_fast.sv — P2-PERSIST-GEN-FAST-SERIAL-STATE-01
// Parent FAST-00 PASS_FUNCTIONAL / FAIL_PHYSICAL (combo 16-way digest + per-slot FF).
// This gate: serial C8 fold; sequential stamp/state memory; TRAIN reset does not
// scrub RAM (gen stamp = validity). Extra cycles OK. G1/G2/G3 sources not edited.
// DDR TB-modeled; addr/GEN/digest FPGA-owned. PROGRAM=NO. SoC ABSENT.
`timescale 1ns / 1ps

module a7ng_persist_gen_fast #(
  parameter int unsigned TXN_W = 16,
  parameter logic [31:0] WRAP_LIMIT = 32'd6
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         learn_i,
  input  logic         freeze_i,
  input  logic         query_valid_i,
  output logic         query_ready_o,
  input  logic [7:0]   query_id_i,
  output logic         snap_valid_o,
  input  logic         snap_ready_i,
  output a7ng_pkg::node_id_t topk_id_o [8],
  output a7ng_pkg::score_t   topk_score_o [8],
  output logic [31:0]  ev_subj_o,
  output logic [7:0]   ev_rel_o,
  output logic [31:0]  ev_obj_o,
  output logic         pending_o,
  output logic [TXN_W-1:0] txn_o,
  input  logic         reward_valid_i,
  input  logic signed [3:0] reward_i,
  input  logic         txn_echo_valid_i,
  input  logic [TXN_W-1:0] txn_echo_i,
  output logic         reward_ready_o,
  output logic         ack_valid_o,
  output logic [2:0]   ack_o,
  output logic         c5_consume_o,
  output logic         c7_ack_valid_o,
  input  logic         c7_ack_ready_i,
  output logic [31:0]  c7_addr_o,
  output logic [31:0]  c8_gen_o,
  output logic [63:0]  c8_sdig_o,
  output logic [7:0]   dig_cyc_o,
  input  logic         flush_i,
  input  logic         reload_i,
  input  logic         bram_kill_i,
  input  logic         train_reset_i,
  output logic         wrap_imminent_o,
  output logic         persist_busy_o,
  output logic         persist_done_o,
  output logic         ddr_req_o,
  output logic         ddr_we_o,
  output logic [4:0]   ddr_addr_o,
  output logic [63:0]  ddr_wdata_o,
  input  logic [63:0]  ddr_rdata_i,
  input  logic         ddr_ack_i
);
  import a7ng_pkg::*;

  localparam logic [7:0] Q_PRE   = 8'd1;
  localparam logic [7:0] Q_HOLD  = 8'd2;
  localparam logic [7:0] Q_UNREL = 8'd3;
  localparam logic [7:0] Q_PRE_B = 8'd5;
  localparam logic [7:0] Q_HOLD_B= 8'd6;

  localparam logic [2:0] S_IDLE=0, S_RD=1, S_ISSUE=2, S_WAIT=3, S_INS=4, S_SNAP=5, S_LATCH=6;
  localparam logic [2:0] P_IDLE=0, P_BOOT=1, P_FLUSH=2, P_RELOAD=3, P_INVAL=4,
                         P_UPD=5, P_DIG=6, P_CLR=7;

  logic [2:0] st, pst;
  logic [7:0] qid;
  logic [3:0] feed_i, fill_n, ins_j, sh_k;
  logic [4:0] slot_i;
  logic train_q, train_b, ins_shift, boot_done, root_valid, ws_live, rd_pend;
  node_id_t new_id;
  score_t   new_s;
  logic [31:0] live_gen;
  logic [63:0] sdig, sdig_acc;
  logic [7:0]  dig_cyc;
  logic signed [8:0] sum8;

  (* ram_style = "block" *) logic [31:0] ws_mem [0:15];
  logic [3:0]  ram_addr;
  logic [31:0] ram_q, ram_wdata;
  logic        ram_we;
  logic [7:0]  rd_pri, rd_pen, rd_stp;

  node_id_t sc_id_i, sc_id_o;
  score_terms_t sc_terms;
  logic sc_v_i, sc_v_o;
  score_t sc_s_o;
  logic latch_v, latch_rdy, cons_v, g2_in_rdy, g2_out_v, g2_out_rdy, g2_sat;
  logic signed [3:0] cons_r, g2_rew, upd_rew;
  logic [31:0] cons_s, cons_o, g2_s, g2_o, upd_s;
  logic [7:0] cons_rel, g2_rel, cons_c, upd_rel;
  logic [15:0] cons_qe, cons_pe, g2_qe, g2_pe, g2_nconf;
  logic cons_k, g2_k, upd_k;
  logic [TXN_W-1:0] cons_txn, g2_txn;
  logic signed [15:0] g2_delta;
  logic [31:0] ls, lo;
  logic [7:0]  lr;

  function automatic logic vis_w(input logic [7:0] stmp);
    return ws_live && (live_gen != 32'd0) && (stmp != 8'd0) && (stmp == live_gen[7:0]);
  endfunction
  function automatic logic [31:0] g_id(input int unsigned i);
    return 32'h1000 + i;
  endfunction
  function automatic logic [31:0] g_subj(input int unsigned i);
    if ((i == 0) || (i == 1)) return 32'h10;
    else if (i < 8)           return 32'h20 + i;
    else                      return 32'h80 + i;
  endfunction
  function automatic logic [7:0] g_rel(input int unsigned i);
    if ((i == 0) || (i == 1)) return 8'd1;
    else                      return 8'd2 + i[7:0];
  endfunction
  function automatic logic [31:0] g_obj(input int unsigned i);
    return 32'h200 + i;
  endfunction
  function automatic int unsigned gi_of(input logic [7:0] q, input int unsigned li);
    if ((q == Q_UNREL) || (q == Q_PRE_B) || (q == Q_HOLD_B)) return 8 + li;
    return li;
  endfunction
  function automatic logic is_train(input logic [7:0] q);
    return (q == Q_PRE) || (q == Q_PRE_B);
  endfunction
  function automatic logic is_bmap(input logic [7:0] q);
    return (q == Q_PRE_B);
  endfunction
  function automatic term_t t8(input int v);
    return term_t'(v);
  endfunction
  function automatic logic [63:0] pack_dig(input int unsigned i,
                                           input logic [7:0] pri,
                                           input logic [7:0] stmp);
    return {8'h00, g_id(i), pri, stmp, i[7:0]};
  endfunction
  function automatic logic [31:0] pack_ws(input logic [7:0] pri,
                                          input logic [7:0] pen,
                                          input logic [7:0] stmp);
    return {8'h00, pri, pen, stmp};
  endfunction
  function automatic score_terms_t base_terms(input logic [7:0] q, input int unsigned li);
    score_terms_t t;
    t = '0;
    if ((q == Q_PRE) || (q == Q_PRE_B)) begin
      case (li)
        0: begin t.entity_match=t8(10); t.intent_match=t8(10); t.relation_match=t8(10); t.context_match=t8(10); end
        1: begin t.entity_match=t8(9);  t.intent_match=t8(9);  t.relation_match=t8(10); t.context_match=t8(10); end
        2: begin t.entity_match=t8(12); t.intent_match=t8(12); t.relation_match=t8(12); t.context_match=t8(8);  end
        3: begin t.entity_match=t8(11); t.intent_match=t8(11); t.relation_match=t8(11); t.context_match=t8(8);  end
        4: begin t.entity_match=t8(8);  t.intent_match=t8(8);  t.relation_match=t8(8);  t.context_match=t8(8);  end
        5: begin t.entity_match=t8(7);  t.intent_match=t8(7);  t.relation_match=t8(7);  t.context_match=t8(7);  end
        6: begin t.entity_match=t8(6);  t.intent_match=t8(6);  t.relation_match=t8(6);  t.context_match=t8(6);  end
        default: begin t.entity_match=t8(5); t.intent_match=t8(5); t.relation_match=t8(5); t.context_match=t8(5); end
      endcase
    end else if ((q == Q_HOLD) || (q == Q_HOLD_B)) begin
      case (li)
        0: begin t.entity_match=t8(9);  t.intent_match=t8(10); t.relation_match=t8(10); t.context_match=t8(10); end
        1: begin t.entity_match=t8(8);  t.intent_match=t8(9);  t.relation_match=t8(10); t.context_match=t8(10); end
        2: begin t.entity_match=t8(12); t.intent_match=t8(12); t.relation_match=t8(11); t.context_match=t8(8);  end
        3: begin t.entity_match=t8(11); t.intent_match=t8(10); t.relation_match=t8(11); t.context_match=t8(8);  end
        4: begin t.entity_match=t8(8);  t.intent_match=t8(7);  t.relation_match=t8(8);  t.context_match=t8(8);  end
        5: begin t.entity_match=t8(7);  t.intent_match=t8(6);  t.relation_match=t8(7);  t.context_match=t8(7);  end
        6: begin t.entity_match=t8(6);  t.intent_match=t8(6);  t.relation_match=t8(5);  t.context_match=t8(6);  end
        default: begin t.entity_match=t8(5); t.intent_match=t8(4); t.relation_match=t8(5); t.context_match=t8(5); end
      endcase
    end else begin
      case (li)
        0: begin t.entity_match=t8(20); t.intent_match=t8(15); t.relation_match=t8(10); t.context_match=t8(5); end
        1: begin t.entity_match=t8(18); t.intent_match=t8(14); t.relation_match=t8(9);  t.context_match=t8(4); end
        2: begin t.entity_match=t8(16); t.intent_match=t8(13); t.relation_match=t8(8);  t.context_match=t8(3); end
        3: begin t.entity_match=t8(14); t.intent_match=t8(12); t.relation_match=t8(7);  t.context_match=t8(2); end
        4: begin t.entity_match=t8(12); t.intent_match=t8(11); t.relation_match=t8(6);  t.context_match=t8(2); end
        5: begin t.entity_match=t8(10); t.intent_match=t8(10); t.relation_match=t8(5);  t.context_match=t8(1); end
        6: begin t.entity_match=t8(8);  t.intent_match=t8(9);  t.relation_match=t8(4);  t.context_match=t8(1); end
        default: begin t.entity_match=t8(6); t.intent_match=t8(8); t.relation_match=t8(3); t.context_match=t8(1); end
      endcase
    end
    return t;
  endfunction
  function automatic logic beats(input score_t sa, input node_id_t ia,
                                 input score_t sb, input node_id_t ib);
    if (sa != sb) return sa > sb;
    return ia < ib;
  endfunction
  function automatic logic signed [7:0] sat8(input logic signed [8:0] x);
    if (x > 9'sd127)  return 8'sd127;
    if (x < -9'sd128) return -8'sd128;
    return x[7:0];
  endfunction

  integer zi;
  initial begin
    for (zi = 0; zi < 16; zi = zi + 1)
      ws_mem[zi] = 32'd0;
  end

  a7ng_scorer_lane u_scorer (
    .clk(clk), .rst_n(rst_n),
    .valid_i(sc_v_i), .cand_id_i(sc_id_i), .terms_i(sc_terms),
    .valid_o(sc_v_o), .cand_id_o(sc_id_o), .score_o(sc_s_o)
  );
  a7ng_feedback_resolver #(.TXN_W(TXN_W)) u_g1 (
    .clk(clk), .rst_n(rst_n), .learn_i(learn_i), .freeze_i(freeze_i),
    .latch_valid_i(latch_v), .latch_ready_o(latch_rdy),
    .subj_i(ls), .rel_i(lr), .obj_i(lo),
    .q_epoch_i(16'd1), .p_epoch_i(16'd1), .conf_i(8'd1), .contradict_i(1'b0),
    .pending_o(pending_o), .txn_o(txn_o),
    .reward_valid_i(reward_valid_i), .reward_i(reward_i),
    .txn_echo_valid_i(txn_echo_valid_i), .txn_echo_i(txn_echo_i),
    .reward_ready_o(reward_ready_o),
    .ack_valid_o(ack_valid_o), .ack_ready_i(1'b1), .ack_o(ack_o),
    .consume_valid_o(cons_v), .consume_ready_i(g2_in_rdy),
    .consume_reward_o(cons_r),
    .consume_subj_o(cons_s), .consume_rel_o(cons_rel), .consume_obj_o(cons_o),
    .consume_q_epoch_o(cons_qe), .consume_p_epoch_o(cons_pe),
    .consume_conf_o(cons_c), .consume_contradict_o(cons_k), .consume_txn_o(cons_txn),
    .n_consume_o(), .n_orphan_o(), .n_range_o(),
    .n_late_o(), .n_drop_o(), .n_dup_o(), .n_mode_o()
  );
  a7ng_context_delta #(.TXN_W(TXN_W)) u_g2 (
    .clk(clk), .rst_n(rst_n),
    .in_valid(cons_v), .in_ready(g2_in_rdy),
    .in_reward(cons_r), .in_native_conf(16'd256),
    .in_subj(cons_s), .in_rel(cons_rel), .in_obj(cons_o),
    .in_q_epoch(cons_qe), .in_p_epoch(cons_pe),
    .in_contradict(cons_k), .in_txn(cons_txn),
    .out_valid(g2_out_v), .out_ready(g2_out_rdy),
    .delta_o(g2_delta), .sat_flag_o(g2_sat),
    .out_reward(g2_rew), .out_native_conf(g2_nconf),
    .out_subj(g2_s), .out_rel(g2_rel), .out_obj(g2_o),
    .out_q_epoch(g2_qe), .out_p_epoch(g2_pe),
    .out_contradict(g2_k), .out_txn(g2_txn)
  );

  assign query_ready_o    = (st == S_IDLE) && (pst == P_IDLE) && boot_done;
  assign persist_busy_o   = (pst != P_IDLE);
  assign wrap_imminent_o  = (live_gen >= WRAP_LIMIT);
  assign c8_gen_o         = live_gen;
  assign c8_sdig_o        = sdig;
  assign dig_cyc_o        = dig_cyc;
  assign c5_consume_o     = cons_v && g2_in_rdy;
  assign g2_out_rdy       = g2_out_v && !c7_ack_valid_o && (pst == P_IDLE) && (st == S_IDLE);
  assign ddr_addr_o       = slot_i;
  assign rd_pri           = ram_q[23:16];
  assign rd_pen           = ram_q[15:8];
  assign rd_stp           = ram_q[7:0];

  always_comb begin
    ram_addr  = 4'd0;
    ram_we    = 1'b0;
    ram_wdata = 32'd0;
    case (pst)
      P_CLR: begin
        ram_addr  = slot_i[3:0];
        ram_we    = 1'b1;
        ram_wdata = 32'd0;
      end
      P_UPD, P_DIG: begin
        ram_addr = slot_i[3:0];
        if ((pst == P_UPD) && rd_pend && (g_subj(int'(slot_i)) == upd_s)) begin
          ram_we    = 1'b1;
          ram_wdata = pack_ws(
            sat8($signed({rd_pri[7], rd_pri}) + $signed({{5{upd_rew[3]}}, upd_rew})),
            (upd_k && (g_rel(int'(slot_i)) == upd_rel))
              ? sat8($signed({rd_pen[7], rd_pen}) + 9'sd3)
              : rd_pen,
            live_gen[7:0]
          );
        end
      end
      P_FLUSH: if (slot_i != 5'd0)
        ram_addr = slot_i[3:0] - 4'd1;
      P_RELOAD: if (slot_i != 5'd0) begin
        ram_addr = slot_i[3:0] - 4'd1;
        if (ddr_req_o && ddr_ack_i) begin
          ram_we    = 1'b1;
          ram_wdata = pack_ws(ddr_rdata_i[31:24], ddr_rdata_i[23:16], ddr_rdata_i[15:8]);
        end
      end
      default: ram_addr = gi_of(qid, int'(feed_i))[3:0];
    endcase
  end

  always_ff @(posedge clk) begin
    if (ram_we)
      ws_mem[ram_addr] <= ram_wdata;
    ram_q <= ws_mem[ram_addr];
  end

  always_comb begin
    sc_v_i = 1'b0; sc_id_i = '0; sc_terms = '0;
    latch_v = 1'b0; ls = 32'h10; lr = 8'd1; lo = 32'h200;
    if (st == S_ISSUE) begin
      sc_v_i  = 1'b1;
      sc_id_i = g_id(gi_of(qid, int'(feed_i)));
      sc_terms = base_terms(qid, int'(feed_i));
      sc_terms.learned_prior = vis_w(rd_stp) ? rd_pri : 8'sd0;
      sc_terms.contradiction_penalty = vis_w(rd_stp) ? rd_pen : 8'sd0;
    end
    if (st == S_LATCH) begin
      latch_v = 1'b1;
      if (train_b) begin
        ls = g_subj(8); lr = g_rel(8); lo = g_obj(8);
      end else begin
        ls = g_subj(0); lr = g_rel(0); lo = g_obj(0);
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE; pst <= P_BOOT; qid <= '0; feed_i <= '0;
      fill_n <= '0; ins_j <= '0; sh_k <= '0; slot_i <= '0;
      train_q <= 0; train_b <= 0; ins_shift <= 0; boot_done <= 0; root_valid <= 0;
      ws_live <= 0; rd_pend <= 0;
      new_id <= '0; new_s <= '0; live_gen <= 32'd1;
      sdig <= '0; sdig_acc <= '0; dig_cyc <= '0;
      snap_valid_o <= 0; persist_done_o <= 0;
      ev_subj_o <= '0; ev_rel_o <= '0; ev_obj_o <= '0;
      c7_ack_valid_o <= 0; c7_addr_o <= '0;
      ddr_req_o <= 0; ddr_we_o <= 0; ddr_wdata_o <= '0;
      upd_s <= '0; upd_rew <= '0; upd_rel <= '0; upd_k <= 0;
      for (int pi = 0; pi < 8; pi++) begin
        topk_id_o[pi] <= '0; topk_score_o[pi] <= '0;
      end
    end else begin
      persist_done_o <= 1'b0;
      if (c7_ack_valid_o && c7_ack_ready_i) c7_ack_valid_o <= 1'b0;

      case (pst)
        P_BOOT: begin
          ddr_we_o <= 1'b0;
          if (!ddr_req_o && !ddr_ack_i)
            ddr_req_o <= 1'b1;
          else if (ddr_req_o && ddr_ack_i) begin
            ddr_req_o <= 1'b0;
            if (ddr_rdata_i[0] && (ddr_rdata_i[32:1] != 32'd0)) begin
              live_gen <= ddr_rdata_i[32:1];
              root_valid <= 1'b1;
              slot_i <= 5'd1; rd_pend <= 0; pst <= P_RELOAD;
            end else begin
              live_gen <= 32'd1; root_valid <= 1'b0;
              slot_i <= 5'd0; pst <= P_CLR;
            end
          end
        end
        P_CLR: begin
          if (slot_i == 5'd15) begin
            ws_live <= 1'b1; sdig <= 64'd0; boot_done <= 1'b1;
            persist_done_o <= 1'b1; pst <= P_IDLE;
          end else
            slot_i <= slot_i + 5'd1;
        end
        P_IDLE: begin
          ddr_req_o <= 1'b0;
          rd_pend <= 1'b0;
          if (bram_kill_i) begin
            ws_live <= 1'b0;
            sdig <= 64'd0;
            persist_done_o <= 1'b1;
          end else if (train_reset_i) begin
            if (live_gen >= WRAP_LIMIT) begin
              slot_i <= 5'd0; pst <= P_INVAL;
            end else begin
              live_gen <= live_gen + 32'd1;
              sdig <= 64'd0;
              persist_done_o <= 1'b1;
            end
          end else if (flush_i) begin
            slot_i <= 5'd0; rd_pend <= 0; pst <= P_FLUSH;
          end else if (reload_i) begin
            slot_i <= 5'd0; boot_done <= 1'b0; ws_live <= 1'b0;
            pst <= P_BOOT;
          end else if (g2_out_v && g2_out_rdy) begin
            upd_s <= g2_s; upd_rew <= g2_rew; upd_rel <= g2_rel; upd_k <= g2_k;
            slot_i <= 5'd0; rd_pend <= 0; sdig_acc <= 64'd0; dig_cyc <= 8'd0;
            c7_addr_o <= 32'(NG_DDR_PRIOR_BASE) + {12'h0, g2_s[15:0], 4'h0};
            pst <= P_UPD;
          end
        end
        P_FLUSH: begin
          ddr_we_o <= 1'b1;
          if (slot_i == 5'd0) begin
            ddr_wdata_o <= {31'd0, live_gen, 1'b1};
            if (!ddr_req_o && !ddr_ack_i)
              ddr_req_o <= 1'b1;
            else if (ddr_req_o && ddr_ack_i) begin
              ddr_req_o <= 1'b0; slot_i <= 5'd1; rd_pend <= 1'b0;
            end
          end else if (!rd_pend) begin
            rd_pend <= 1'b1;
          end else begin
            ddr_wdata_o <= {g_id(int'(slot_i-1)), rd_pri, rd_pen, rd_stp, 8'd0};
            if (!ddr_req_o && !ddr_ack_i)
              ddr_req_o <= 1'b1;
            else if (ddr_req_o && ddr_ack_i) begin
              ddr_req_o <= 1'b0; rd_pend <= 1'b0;
              if (slot_i == 5'd16) begin
                root_valid <= 1'b1; persist_done_o <= 1'b1; pst <= P_IDLE;
              end else
                slot_i <= slot_i + 5'd1;
            end
          end
        end
        P_RELOAD: begin
          ddr_we_o <= 1'b0;
          if (!ddr_req_o && !ddr_ack_i)
            ddr_req_o <= 1'b1;
          else if (ddr_req_o && ddr_ack_i) begin
            ddr_req_o <= 1'b0;
            if (slot_i == 5'd16) begin
              slot_i <= 5'd0; rd_pend <= 0; sdig_acc <= 64'd0; dig_cyc <= 8'd0;
              ws_live <= 1'b1; pst <= P_DIG;
            end else
              slot_i <= slot_i + 5'd1;
          end
        end
        P_INVAL: begin
          ddr_we_o <= 1'b1; ddr_wdata_o <= 64'd0;
          if (!ddr_req_o && !ddr_ack_i)
            ddr_req_o <= 1'b1;
          else if (ddr_req_o && ddr_ack_i) begin
            ddr_req_o <= 1'b0;
            if (slot_i == 5'd16) begin
              root_valid <= 1'b0; sdig <= 64'd0;
              persist_done_o <= 1'b1; pst <= P_IDLE;
            end else
              slot_i <= slot_i + 5'd1;
          end
        end
        P_UPD, P_DIG: begin
          dig_cyc <= dig_cyc + 8'd1;
          if (!rd_pend)
            rd_pend <= 1'b1;
          else begin
            begin : fold
              logic [7:0]  npri, nstp;
              logic [63:0] acc_n;
              npri = rd_pri;
              nstp = rd_stp;
              if ((pst == P_UPD) && (g_subj(int'(slot_i)) == upd_s)) begin
                npri = sat8($signed({rd_pri[7], rd_pri}) + $signed({{5{upd_rew[3]}}, upd_rew}));
                nstp = live_gen[7:0];
              end
              acc_n = vis_w(nstp) ? (sdig_acc ^ pack_dig(int'(slot_i), npri, nstp))
                                  : sdig_acc;
              sdig_acc <= acc_n;
              rd_pend <= 1'b0;
              if (slot_i == 5'd15) begin
                sdig <= acc_n;
                if (pst == P_UPD) begin
                  c7_ack_valid_o <= 1'b1;
                  persist_done_o <= 1'b1;
                end else begin
                  boot_done <= 1'b1;
                  persist_done_o <= 1'b1;
                end
                pst <= P_IDLE;
              end else
                slot_i <= slot_i + 5'd1;
            end
          end
        end
        default: pst <= P_IDLE;
      endcase

      if ((pst == P_IDLE) && boot_done) begin
        case (st)
          S_IDLE: if (query_valid_i) begin
            qid <= query_id_i;
            train_q <= is_train(query_id_i);
            train_b <= is_bmap(query_id_i);
            feed_i <= 0; fill_n <= 0; snap_valid_o <= 0;
            st <= S_RD;
          end
          S_RD: st <= S_ISSUE;
          S_ISSUE: st <= S_WAIT;
          S_WAIT: if (sc_v_o) begin
            new_id <= sc_id_o; new_s <= sc_s_o;
            ins_j <= 0; ins_shift <= 0; st <= S_INS;
          end
          S_INS: begin
            if (!ins_shift) begin
              if ((ins_j < fill_n) && beats(topk_score_o[ins_j], topk_id_o[ins_j], new_s, new_id))
                ins_j <= ins_j + 1;
              else begin ins_shift <= 1; sh_k <= fill_n; end
            end else if (sh_k > ins_j) begin
              topk_id_o[sh_k] <= topk_id_o[sh_k-1];
              topk_score_o[sh_k] <= topk_score_o[sh_k-1];
              sh_k <= sh_k - 1;
            end else begin
              topk_id_o[ins_j] <= new_id; topk_score_o[ins_j] <= new_s;
              fill_n <= fill_n + 1; ins_shift <= 0; ins_j <= 0;
              if (feed_i == 7) st <= S_SNAP;
              else begin feed_i <= feed_i + 1; st <= S_RD; end
            end
          end
          S_SNAP: begin
            ev_subj_o <= g_subj(int'(topk_id_o[0][3:0]));
            ev_rel_o  <= g_rel(int'(topk_id_o[0][3:0]));
            ev_obj_o  <= g_obj(int'(topk_id_o[0][3:0]));
            snap_valid_o <= 1;
            if (snap_valid_o && snap_ready_i) begin
              snap_valid_o <= 0;
              st <= train_q ? S_LATCH : S_IDLE;
            end
          end
          S_LATCH: if (latch_v && latch_rdy) st <= S_IDLE;
          default: st <= S_IDLE;
        endcase
      end
    end
  end
endmodule
