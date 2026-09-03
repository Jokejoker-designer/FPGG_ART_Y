// a7ng_learned_prior_store.sv — P2-GATE14-C9-LEARNED-PRIOR-GRAPH-03
// G4 pri/pen/gen-stamp law keyed by FPGA {subj,rel,obj}. Serial lookup.
// No scorer, no TopK, no LM, no host idx/address. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_learned_prior_store #(
  parameter int unsigned DEPTH = 32,
  parameter logic [31:0] WRAP_LIMIT = 32'd6
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         learn_i,
  input  logic         freeze_i,
  input  logic         flush_i,
  input  logic         reload_i,
  input  logic         bram_kill_i,
  input  logic         train_reset_i,
  output logic         persist_busy_o,
  output logic         persist_done_o,
  output logic         boot_done_o,
  output logic [31:0]  live_gen_o,
  output logic [63:0]  sdig_o,
  output logic         wrap_imminent_o,
  // G2 consume (FPGA-owned)
  input  logic         upd_valid_i,
  output logic         upd_ready_o,
  input  logic [31:0]  upd_subj_i,
  input  logic [7:0]   upd_rel_i,
  input  logic [31:0]  upd_obj_i,
  input  logic signed [3:0] upd_rew_i,
  input  logic         upd_contra_i,
  // serial lookup
  input  logic         lk_go_i,
  input  logic [31:0]  lk_subj_i,
  input  logic [7:0]   lk_rel_i,
  input  logic [31:0]  lk_obj_i,
  output logic         lk_busy_o,
  output logic         lk_done_o,
  output logic         lk_hit_o,
  output logic signed [7:0] lk_pri_o,
  output logic signed [7:0] lk_pen_o,
  // C7 observe-only
  output logic         c7_ack_valid_o,
  input  logic         c7_ack_ready_i,
  output logic [31:0]  c7_addr_o,
  output logic [15:0]  c7_commit_seq_o,
  output logic [15:0]  c7_ack_count_o,
  // TB-modeled DDR
  output logic         ddr_req_o,
  output logic         ddr_we_o,
  output logic [7:0]   ddr_addr_o,
  output logic [63:0]  ddr_wdata_o,
  input  logic [63:0]  ddr_rdata_i,
  input  logic         ddr_ack_i
);
  import a7ng_pkg::*;

  localparam logic [2:0] P_BOOT=0, P_CLR=1, P_IDLE=2, P_UPD=3, P_FLUSH=4,
                         P_RELOAD=5, P_INVAL=6, P_LK=7;

  logic [2:0] pst;
  logic [5:0] slot_i;
  logic       rd_pend, ws_live, wrote, boot_done;
  logic [31:0] live_gen;
  logic [63:0] sdig, sdig_acc;
  logic [4:0]  first_free;
  logic        have_free;
  logic [31:0] us, uo;
  logic [7:0]  ur;
  logic signed [3:0] urew;
  logic        uk;
  logic [31:0] ls, lo;
  logic [7:0]  lr;
  logic [15:0] commit_seq, ack_count;
  logic        lk_busy, lk_done, lk_hit;
  logic signed [7:0] lk_pri, lk_pen;

  (* ram_style = "block" *) logic [96:0] ws_mem [0:31];
  logic [4:0]  ram_addr;
  logic [96:0] ram_q, ram_wdata;
  logic        ram_we;

  function automatic logic vis_w(input logic occ, input logic [7:0] stmp);
    return ws_live && (live_gen != 32'd0) && occ && (stmp != 8'd0) && (stmp == live_gen[7:0]);
  endfunction
  function automatic logic signed [7:0] sat8(input logic signed [8:0] x);
    if (x > 9'sd127)  return 8'sd127;
    if (x < -9'sd128) return -8'sd128;
    return x[7:0];
  endfunction
  function automatic logic [96:0] pack_e(
      input logic occ, input logic [7:0] stmp, input logic [7:0] pen,
      input logic [7:0] pri, input logic [7:0] rel,
      input logic [31:0] obj, input logic [31:0] subj);
    return {occ, stmp, pen, pri, rel, obj, subj};
  endfunction

  wire        q_occ  = ram_q[96];
  wire [7:0]  q_stp  = ram_q[95:88];
  wire [7:0]  q_pen  = ram_q[87:80];
  wire [7:0]  q_pri  = ram_q[79:72];
  wire [7:0]  q_rel  = ram_q[71:64];
  wire [31:0] q_obj  = ram_q[63:32];
  wire [31:0] q_subj = ram_q[31:0];

  integer zi;
  initial begin
    for (zi = 0; zi < 32; zi = zi + 1)
      ws_mem[zi] = 97'd0;
  end

  assign persist_busy_o   = (pst != P_IDLE) || lk_busy;
  assign boot_done_o      = boot_done;
  assign live_gen_o       = live_gen;
  assign sdig_o           = sdig;
  assign wrap_imminent_o  = (live_gen >= WRAP_LIMIT);
  assign upd_ready_o      = (pst == P_IDLE) && boot_done && !lk_busy && learn_i && !freeze_i;
  assign lk_busy_o        = lk_busy;
  assign lk_done_o        = lk_done;
  assign lk_hit_o         = lk_hit;
  assign lk_pri_o         = lk_pri;
  assign lk_pen_o         = lk_pen;
  assign c7_commit_seq_o  = commit_seq;
  assign c7_ack_count_o   = ack_count;
  assign ddr_addr_o       = {2'b0, slot_i};

  always_comb begin
    ram_addr  = 5'd0;
    ram_we    = 1'b0;
    ram_wdata = 97'd0;
    unique case (pst)
      P_CLR: begin
        ram_addr  = slot_i[4:0];
        ram_we    = 1'b1;
        ram_wdata = 97'd0;
      end
      P_UPD, P_LK: begin
        ram_addr = slot_i[4:0];
        if ((pst == P_UPD) && rd_pend && q_occ &&
            (q_subj == us) && (q_rel == ur) && (q_obj == uo)) begin
          ram_we    = 1'b1;
          ram_wdata = pack_e(1'b1, live_gen[7:0],
            uk ? sat8($signed({q_pen[7], q_pen}) + 9'sd3) : q_pen,
            sat8($signed({q_pri[7], q_pri}) + $signed({{5{urew[3]}}, urew})),
            ur, uo, us);
        end
      end
      P_FLUSH: if (slot_i != 6'd0)
        ram_addr = slot_i[4:0] - 5'd1;
      P_RELOAD: if (slot_i != 6'd0) begin
        ram_addr = slot_i[4:0] - 5'd1;
        if (ddr_req_o && ddr_ack_i) begin
          ram_we    = 1'b1;
          ram_wdata = pack_e(ddr_rdata_i[7:0] != 8'd0,
                             ddr_rdata_i[7:0], ddr_rdata_i[15:8], ddr_rdata_i[23:16],
                             ddr_rdata_i[31:24],
                             {16'd0, ddr_rdata_i[47:32]}, {16'd0, ddr_rdata_i[63:48]});
        end
      end
      default: ram_addr = 5'd0;
    endcase
    if ((pst == P_UPD) && (slot_i == 6'd32) && !wrote && have_free) begin
      ram_addr  = first_free;
      ram_we    = 1'b1;
      ram_wdata = pack_e(1'b1, live_gen[7:0], 8'd0,
        sat8($signed(9'sd0) + $signed({{5{urew[3]}}, urew})), ur, uo, us);
    end
  end

  always_ff @(posedge clk) begin
    if (ram_we)
      ws_mem[ram_addr] <= ram_wdata;
    ram_q <= ws_mem[ram_addr];
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pst <= P_BOOT; slot_i <= '0; rd_pend <= 0; ws_live <= 0;
      wrote <= 0; boot_done <= 0; live_gen <= 32'd1; sdig <= '0; sdig_acc <= '0;
      first_free <= '0; have_free <= 0;
      us <= '0; uo <= '0; ur <= '0; urew <= '0; uk <= 0;
      ls <= '0; lo <= '0; lr <= '0;
      commit_seq <= '0; ack_count <= '0;
      persist_done_o <= 0; c7_ack_valid_o <= 0; c7_addr_o <= '0;
      ddr_req_o <= 0; ddr_we_o <= 0; ddr_wdata_o <= '0;
      lk_busy <= 0; lk_done <= 0; lk_hit <= 0; lk_pri <= '0; lk_pen <= '0;
    end else begin
      persist_done_o <= 1'b0;
      lk_done <= 1'b0;
      if (c7_ack_valid_o && c7_ack_ready_i) c7_ack_valid_o <= 1'b0;

      unique case (pst)
        P_BOOT: begin
          ddr_we_o <= 1'b0;
          slot_i <= 6'd0; rd_pend <= 0;
          if (!ddr_req_o && !ddr_ack_i)
            ddr_req_o <= 1'b1;
          else if (ddr_req_o && ddr_ack_i) begin
            ddr_req_o <= 1'b0;
            if (ddr_rdata_i[0] && (ddr_rdata_i[32:1] != 32'd0)) begin
              live_gen <= ddr_rdata_i[32:1];
              slot_i <= 6'd1; pst <= P_RELOAD;
            end else begin
              live_gen <= 32'd1;
              slot_i <= 6'd0; pst <= P_CLR;
            end
          end
        end
        P_CLR: begin
          if (slot_i == 6'd31) begin
            ws_live <= 1'b1; sdig <= 64'd0; boot_done <= 1'b1;
            persist_done_o <= 1'b1; pst <= P_IDLE;
          end else
            slot_i <= slot_i + 6'd1;
        end
        P_IDLE: begin
          ddr_req_o <= 1'b0;
          rd_pend <= 1'b0;
          lk_busy <= 1'b0;
          if (bram_kill_i) begin
            ws_live <= 1'b0; sdig <= 64'd0; persist_done_o <= 1'b1;
          end else if (train_reset_i) begin
            if (live_gen >= WRAP_LIMIT) begin
              slot_i <= 6'd0; pst <= P_INVAL;
            end else begin
              live_gen <= live_gen + 32'd1; sdig <= 64'd0;
              persist_done_o <= 1'b1;
            end
          end else if (flush_i) begin
            slot_i <= 6'd0; rd_pend <= 0; pst <= P_FLUSH;
          end else if (reload_i) begin
            slot_i <= 6'd0; boot_done <= 1'b0; ws_live <= 1'b0; pst <= P_BOOT;
          end else if (upd_valid_i && upd_ready_o) begin
            us <= upd_subj_i; ur <= upd_rel_i; uo <= upd_obj_i;
            urew <= upd_rew_i; uk <= upd_contra_i;
            c7_addr_o <= 32'(NG_DDR_PRIOR_BASE) + {12'h0, upd_subj_i[15:0], 4'h0};
            slot_i <= 6'd0; rd_pend <= 0; wrote <= 0; have_free <= 0;
            sdig_acc <= 64'd0; pst <= P_UPD;
          end else if (lk_go_i) begin
            ls <= lk_subj_i; lr <= lk_rel_i; lo <= lk_obj_i;
            slot_i <= 6'd0; rd_pend <= 0; lk_busy <= 1; lk_hit <= 0;
            lk_pri <= 8'sd0; lk_pen <= 8'sd0; pst <= P_LK;
          end
        end
        P_LK: begin
          if (!rd_pend) rd_pend <= 1'b1;
          else begin
            if (vis_w(q_occ, q_stp) && (q_subj == ls) && (q_rel == lr) && (q_obj == lo)) begin
              lk_hit <= 1'b1; lk_pri <= q_pri; lk_pen <= q_pen;
              lk_done <= 1'b1; lk_busy <= 1'b0; rd_pend <= 0; pst <= P_IDLE;
            end else if (slot_i == 6'd31) begin
              lk_done <= 1'b1; lk_busy <= 1'b0; rd_pend <= 0; pst <= P_IDLE;
            end else begin
              slot_i <= slot_i + 6'd1; rd_pend <= 1'b0;
            end
          end
        end
        P_UPD: begin
          if (slot_i < 6'd32) begin
            if (!rd_pend) rd_pend <= 1'b1;
            else begin
              if (!q_occ && !have_free) begin
                have_free <= 1'b1; first_free <= slot_i[4:0];
              end
              if (ram_we) begin
                wrote <= 1'b1;
                commit_seq <= commit_seq + 16'd1;
              end
              begin : fold
                logic [7:0] npri, nstp;
                logic occ_n;
                npri = q_pri; nstp = q_stp; occ_n = q_occ;
                if (q_occ && (q_subj == us) && (q_rel == ur) && (q_obj == uo)) begin
                  npri = sat8($signed({q_pri[7], q_pri}) + $signed({{5{urew[3]}}, urew}));
                  nstp = live_gen[7:0]; occ_n = 1'b1;
                end
                if (vis_w(occ_n, nstp))
                  sdig_acc <= sdig_acc ^ {24'd0, npri, nstp, 2'b00, slot_i};
              end
              rd_pend <= 1'b0;
              slot_i <= slot_i + 6'd1;
            end
          end else begin
            if (ram_we) begin
              wrote <= 1'b1;
              commit_seq <= commit_seq + 16'd1;
            end
            sdig <= sdig_acc;
            ack_count <= ack_count + 16'd1;
            c7_ack_valid_o <= 1'b1;
            persist_done_o <= 1'b1;
            pst <= P_IDLE;
          end
        end
        P_FLUSH: begin
          ddr_we_o <= 1'b1;
          if (slot_i == 6'd0) begin
            ddr_wdata_o <= {31'd0, live_gen, 1'b1};
            if (!ddr_req_o && !ddr_ack_i)
              ddr_req_o <= 1'b1;
            else if (ddr_req_o && ddr_ack_i) begin
              ddr_req_o <= 1'b0; slot_i <= 6'd1; rd_pend <= 0;
            end
          end else if (!rd_pend) begin
            rd_pend <= 1'b1;
          end else begin
            // 16+16+8+8+8+8=64. occ recovered as stamp!=0.
            ddr_wdata_o <= {q_subj[15:0], q_obj[15:0], q_rel, q_pri, q_pen, q_stp};
            if (!ddr_req_o && !ddr_ack_i)
              ddr_req_o <= 1'b1;
            else if (ddr_req_o && ddr_ack_i) begin
              ddr_req_o <= 1'b0; rd_pend <= 0;
              if (slot_i == 6'd32) begin
                persist_done_o <= 1'b1; pst <= P_IDLE;
              end else
                slot_i <= slot_i + 6'd1;
            end
          end
        end
        P_RELOAD: begin
          ddr_we_o <= 1'b0;
          if (!ddr_req_o && !ddr_ack_i)
            ddr_req_o <= 1'b1;
          else if (ddr_req_o && ddr_ack_i) begin
            ddr_req_o <= 1'b0;
            if (slot_i == 6'd32) begin
              ws_live <= 1'b1; boot_done <= 1'b1; persist_done_o <= 1'b1; pst <= P_IDLE;
            end else
              slot_i <= slot_i + 6'd1;
          end
        end
        P_INVAL: begin
          ddr_we_o <= 1'b1; ddr_wdata_o <= 64'd0;
          if (!ddr_req_o && !ddr_ack_i)
            ddr_req_o <= 1'b1;
          else if (ddr_req_o && ddr_ack_i) begin
            ddr_req_o <= 1'b0;
            if (slot_i == 6'd32) begin
              sdig <= 64'd0; persist_done_o <= 1'b1; pst <= P_IDLE;
            end else
              slot_i <= slot_i + 6'd1;
          end
        end
        default: pst <= P_IDLE;
      endcase
    end
  end
endmodule
