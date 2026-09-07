// a7ng_query_struct_extract.sv — U3Q-R3 + U6Q lexicon timing
// Law: qse-v1-lexicon-hdc-00 (outputs unchanged; match split 30+30 + apply)
// Raw tokens → FPGA entity/intent/relation/context packet + route keys.
// CRC is debug fingerprint only. No host semantic ports. PROGRAM=NO.
`timescale 1ns / 1ps
`include "a7ng_gate14_crc.svh"
`include "qse_lexicon.svh"

module a7ng_query_struct_extract (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        tok_valid_i,
  output logic        tok_ready_o,
  input  logic [7:0]  tok_i,
  input  logic        fire_i,
  input  logic        retire_i,
  output logic        busy_o,
  output logic        accepted_o,
  output logic        valid_o,
  output logic [7:0]  entity_id_o,
  output logic [7:0]  intent_id_o,
  output logic [7:0]  relation_id_o,
  output logic [7:0]  context_id_o,
  output logic [63:0] entity_cue_o,
  output logic [63:0] intent_cue_o,
  output logic [63:0] relation_cue_o,
  output logic [63:0] context_cue_o,
  output logic [15:0] crc16_dbg_o,
  output logic [15:0] k0_o,
  output logic [15:0] k1_o,
  output logic [15:0] k2_o,
  output logic [15:0] k3_o,
  // U4A-R6: semantic route validity from bind/hit, NOT from key!=0
  output logic        k0_valid_o,
  output logic        k1_valid_o,
  output logic        k2_valid_o,
  output logic        k3_valid_o,
  output logic [15:0] n_host_entity_o,
  output logic [15:0] n_host_intent_o,
  output logic [15:0] n_host_hash_o,
  output logic [15:0] n_host_shard_o,
  output logic [15:0] n_host_bucket_o,
  output logic [15:0] n_host_cand_o,
  output logic [15:0] n_host_winner_o,
  output logic [15:0] n_host_addr_o,
  output logic [15:0] n_host_relpath_o,
  output logic [15:0] n_host_next_o,
  output logic [15:0] n_host_answer_o
);
  import a7ng_pkg::*;

  localparam int unsigned MAX_BYTES = 48;
  localparam int unsigned MAX_WORDS = 8;

  logic [7:0]  n_bytes, n_words, wlen;
  logic [95:0] wbuf;
  logic [15:0] crc_acc;
  logic [7:0]  eid, iid, rid, xid;
  cue_t        ecue, icue, rcue, xcue;
  logic        eh, ih, rh, xh;

  assign n_host_entity_o  = 16'd0;
  assign n_host_intent_o  = 16'd0;
  assign n_host_hash_o    = 16'd0;
  assign n_host_shard_o   = 16'd0;
  assign n_host_bucket_o  = 16'd0;
  assign n_host_cand_o    = 16'd0;
  assign n_host_winner_o  = 16'd0;
  assign n_host_addr_o    = 16'd0;
  assign n_host_relpath_o = 16'd0;
  assign n_host_next_o    = 16'd0;
  assign n_host_answer_o  = 16'd0;

  typedef enum logic [1:0] {
    ST_ACC = 2'd0,
    ST_M0  = 2'd1,
    ST_M1  = 2'd2,
    ST_AP  = 2'd3
  } st_t;
  st_t st;
  logic fire_pend;
  logic        hit0_r, hit_r;
  logic [7:0]  hcls0_r, hid0_r, hcls_r, hid_r;
  cue_t        bcue_r;

  localparam int unsigned QSE_SPLIT = 30;

  assign tok_ready_o = rst_n && (st == ST_ACC) && !valid_o
                    && (n_bytes < MAX_BYTES[7:0]) && (n_words < MAX_WORDS[7:0]);
  assign busy_o      = valid_o || (st != ST_ACC);
  assign k0_o        = {entity_id_o, intent_id_o};
  assign k1_o        = {relation_id_o, context_id_o};
  assign k2_o        = entity_cue_o[15:0];
  assign k3_o        = intent_cue_o[15:0];

  function automatic logic [7:0] lc(input logic [7:0] t);
    if ((t >= 8'h41) && (t <= 8'h5A))
      return t + 8'h20;
    return t;
  endfunction

  function automatic cue_t bindb(input cue_t c, input logic [7:0] b);
    return ng_rotl1(c) ^ {56'd0, b};
  endfunction

  logic        do_fire, do_space, start_match, fire_now;
  logic        hit0, hit1;
  logic [7:0]  hcls0, hid0, hcls1, hid1;
  cue_t        bcue;
  logic [7:0]  eid_n, iid_n, rid_n, xid_n;
  cue_t        ecue_n, icue_n, rcue_n, xcue_n;
  logic        eh_n, ih_n, rh_n, xh_n;
  integer      li, bi;

  assign do_space    = tok_valid_i && tok_ready_o && (tok_i == 8'h20) && (wlen != 8'd0);
  assign do_fire     = (st == ST_ACC) && fire_i && !valid_o
                    && ((wlen != 8'd0) || (n_words != 8'd0) || (n_bytes != 8'd0));
  assign start_match = do_space || (do_fire && (wlen != 8'd0));
  assign fire_now    = do_fire && (wlen == 8'd0);

  always_comb begin
    hit0 = 1'b0; hcls0 = 8'd0; hid0 = 8'd0;
    for (li = 0; li < QSE_SPLIT; li = li + 1) begin
      if ((wlen == QSE_LEN[li]) && (wbuf == QSE_WORD[li])) begin
        if (!hit0) begin
          hit0  = 1'b1;
          hcls0 = QSE_CLS[li];
          hid0  = QSE_ID[li];
        end else if ((QSE_CLS[li] == hcls0) && (QSE_ID[li] < hid0))
          hid0 = QSE_ID[li];
      end
    end
    hit1 = hit0_r; hcls1 = hcls0_r; hid1 = hid0_r;
    for (li = QSE_SPLIT; li < QSE_N_LEX; li = li + 1) begin
      if ((wlen == QSE_LEN[li]) && (wbuf == QSE_WORD[li])) begin
        if (!hit1) begin
          hit1  = 1'b1;
          hcls1 = QSE_CLS[li];
          hid1  = QSE_ID[li];
        end else if ((QSE_CLS[li] == hcls1) && (QSE_ID[li] < hid1))
          hid1 = QSE_ID[li];
      end
    end
    bcue = 64'd0;
    for (bi = 0; bi < 12; bi = bi + 1)
      if (bi < wlen)
        bcue = bindb(bcue, wbuf[8*bi +: 8]);
    eid_n = eid; iid_n = iid; rid_n = rid; xid_n = xid;
    ecue_n = ecue; icue_n = icue; rcue_n = rcue; xcue_n = xcue;
    eh_n = eh; ih_n = ih; rh_n = rh; xh_n = xh;
    if (st == ST_AP) begin
      if (hit_r && (hcls_r == 8'd1)) begin
        if ((eid == 8'd0) || (hid_r < eid)) eid_n = hid_r;
        ecue_n = ecue ^ bcue_r;
        eh_n = 1'b1;
      end else if (hit_r && (hcls_r == 8'd2)) begin
        if ((iid == 8'd0) || (hid_r < iid)) iid_n = hid_r;
        icue_n = icue ^ bcue_r;
        ih_n = 1'b1;
      end else if (hit_r && (hcls_r == 8'd3)) begin
        if ((rid == 8'd0) || (hid_r < rid)) rid_n = hid_r;
        rcue_n = rcue ^ bcue_r;
        rh_n = 1'b1;
      end else if (hit_r && (hcls_r == 8'd4)) begin
        if ((xid == 8'd0) || (hid_r < xid)) xid_n = hid_r;
        xcue_n = xcue ^ bcue_r;
        xh_n = 1'b1;
      end else
        xcue_n = xcue ^ bcue_r;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= ST_ACC; fire_pend <= 1'b0;
      hit0_r <= 1'b0; hit_r <= 1'b0;
      hcls0_r <= 8'd0; hid0_r <= 8'd0; hcls_r <= 8'd0; hid_r <= 8'd0;
      bcue_r <= 64'd0;
      n_bytes <= 8'd0; n_words <= 8'd0; wlen <= 8'd0; wbuf <= 96'd0;
      crc_acc <= 16'hFFFF;
      eid <= 8'd0; iid <= 8'd0; rid <= 8'd0; xid <= 8'd0;
      ecue <= 64'd0; icue <= 64'd0; rcue <= 64'd0; xcue <= 64'd0;
      eh <= 1'b0; ih <= 1'b0; rh <= 1'b0; xh <= 1'b0;
      accepted_o <= 1'b0;
      valid_o <= 1'b0;
      entity_id_o <= 8'd0; intent_id_o <= 8'd0; relation_id_o <= 8'd0; context_id_o <= 8'd0;
      entity_cue_o <= 64'd0; intent_cue_o <= 64'd0; relation_cue_o <= 64'd0; context_cue_o <= 64'd0;
      crc16_dbg_o <= 16'd0;
      k0_valid_o <= 1'b0; k1_valid_o <= 1'b0; k2_valid_o <= 1'b0; k3_valid_o <= 1'b0;
    end else begin
      accepted_o <= 1'b0;
      if (valid_o) begin
        if (retire_i) begin
          valid_o <= 1'b0;
          st <= ST_ACC; fire_pend <= 1'b0;
          n_bytes <= 8'd0; n_words <= 8'd0; wlen <= 8'd0; wbuf <= 96'd0;
          crc_acc <= 16'hFFFF;
          eid <= 8'd0; iid <= 8'd0; rid <= 8'd0; xid <= 8'd0;
          ecue <= 64'd0; icue <= 64'd0; rcue <= 64'd0; xcue <= 64'd0;
          eh <= 1'b0; ih <= 1'b0; rh <= 1'b0; xh <= 1'b0;
          k0_valid_o <= 1'b0; k1_valid_o <= 1'b0; k2_valid_o <= 1'b0; k3_valid_o <= 1'b0;
        end
      end else begin
        unique case (st)
          ST_ACC: begin
            if (tok_valid_i && tok_ready_o) begin
              crc_acc <= crc16_byte(crc_acc, tok_i);
              n_bytes <= n_bytes + 8'd1;
              if (tok_i == 8'h20) begin
                if (wlen != 8'd0) begin
                  fire_pend <= 1'b0;
                  st <= ST_M0;
                end
              end else if (wlen < QSE_MAX_WORD[7:0]) begin
                wbuf[8*wlen +: 8] <= lc(tok_i);
                wlen <= wlen + 8'd1;
              end
            end else if (start_match) begin
              fire_pend <= 1'b1;
              st <= ST_M0;
            end else if (fire_now) begin
              entity_id_o    <= eid;
              intent_id_o    <= iid;
              relation_id_o  <= rid;
              context_id_o   <= xid;
              entity_cue_o   <= ecue;
              intent_cue_o   <= icue;
              relation_cue_o <= rcue;
              context_cue_o  <= xcue;
              crc16_dbg_o    <= crc_acc;
              k0_valid_o <= eh | ih;
              k1_valid_o <= rh | xh;
              k2_valid_o <= eh;
              k3_valid_o <= ih;
              valid_o    <= 1'b1;
              accepted_o <= 1'b1;
            end
          end
          ST_M0: begin
            hit0_r  <= hit0;
            hcls0_r <= hcls0;
            hid0_r  <= hid0;
            st      <= ST_M1;
          end
          ST_M1: begin
            hit_r   <= hit1;
            hcls_r  <= hcls1;
            hid_r   <= hid1;
            bcue_r  <= bcue;
            st      <= ST_AP;
          end
          ST_AP: begin
            eid <= eid_n; iid <= iid_n; rid <= rid_n; xid <= xid_n;
            ecue <= ecue_n; icue <= icue_n; rcue <= rcue_n; xcue <= xcue_n;
            eh <= eh_n; ih <= ih_n; rh <= rh_n; xh <= xh_n;
            n_words <= n_words + 8'd1;
            wlen <= 8'd0;
            wbuf <= 96'd0;
            if (fire_pend) begin
              entity_id_o    <= eid_n;
              intent_id_o    <= iid_n;
              relation_id_o  <= rid_n;
              context_id_o   <= xid_n;
              entity_cue_o   <= ecue_n;
              intent_cue_o   <= icue_n;
              relation_cue_o <= rcue_n;
              context_cue_o  <= xcue_n;
              crc16_dbg_o    <= crc_acc;
              k0_valid_o <= eh_n | ih_n;
              k1_valid_o <= rh_n | xh_n;
              k2_valid_o <= eh_n;
              k3_valid_o <= ih_n;
              valid_o    <= 1'b1;
              accepted_o <= 1'b1;
            end
            fire_pend <= 1'b0;
            st <= ST_ACC;
          end
          default: st <= ST_ACC;
        endcase
      end
    end
  end
endmodule
