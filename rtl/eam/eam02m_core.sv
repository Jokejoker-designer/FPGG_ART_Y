`timescale 1ns/1ps
import a7eam00_pkg::*;
import a7eam01r_pkg::*;
import a7eam02m_pkg::*;
// Multi-cue bind on frozen 01R. Episode table owns the value.
// 01R token field = episode_id. Host never sends a winner address.
module eam02m_core (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         open_start,
    input  logic         bind_start,
    input  logic         probe_start,
    input  logic         teacher_off_cmd,
    input  logic         soft_rst,
    input  logic         clr_stat,
    input  logic [7:0]   in_episode,
    input  logic [7:0]   in_token,
    input  logic [63:0]  in_key,
    input  logic [127:0] in_vec,
    input  logic [7:0]   hit_max,
    input  logic [7:0]   margin_min,
    output logic         idle,
    output logic         result_valid,
    output logic         hit,
    output logic         collide,
    output logic         nack,
    output logic [7:0]   nack_code,
    output logic [7:0]   out_episode,
    output logic [7:0]   out_token,
    output logic [7:0]   out_cue_n,
    output logic [6:0]   out_hamming,
    output logic [6:0]   out_second,
    output logic [7:0]   out_margin,
    output logic         teacher_off,
    output logic [31:0]  hit_cnt,
    output logic [31:0]  miss_cnt,
    output logic [31:0]  qry_cnt,
    output logic [15:0]  cand_n,
    output logic [15:0]  ovf_n,
    output logic [7:0]   epoch
);
    typedef enum logic [3:0] {
        S_IDLE,
        S_OPEN,
        S_BIND_RD, S_BIND_RLAT, S_BIND_ISSUE, S_BIND_WAIT,
        S_BIND_MAP, S_BIND_WAITM, S_BIND_COMMIT,
        S_PROBE_ISSUE, S_PROBE_WAIT, S_PROBE_RD, S_PROBE_RLAT,
        S_OUT
    } st_t;

    st_t st;
    logic        teach;
    logic [7:0]  alloc;
    logic [7:0]  ep_gen;
    logic [8:0]  n_open;
    logic [7:0]  ep_sel;
    e2m_ep_t     ep_lat, ep_q, ep_wd;
    logic        ep_we;
    logic [7:0]  ep_ra, ep_wa;
    logic        got_r, e1_map;
    logic        e1_start, e1_soft, e1_clr;
    logic        e1_idle, e1_rvalid, e1_hit;
    logic [7:0]  e1_tok, e1_conf, e1_omarg, e1_epoch;
    logic [6:0]  e1_ham, e1_sec;
    logic [127:0] e1_vec;
    logic [15:0] e1_cand, e1_ovf;
    logic [31:0] e1_hitc, e1_missc, e1_qryc;
    logic        lat_hit;
    logic [7:0]  lat_tok;
    logic [6:0]  lat_ham, lat_sec;
    logic [7:0]  lat_marg;
    logic [63:0] qkey;
    logic [127:0] qvec;
    logic [7:0]  qtok;

    (* ram_style = "block" *) e2m_ep_t eps [0:E2M_EPS-1];

    integer ei;
    initial begin
        for (ei = 0; ei < E2M_EPS; ei = ei + 1)
            eps[ei] = '0;
    end

    always_ff @(posedge clk) begin
        ep_q <= eps[ep_ra];
        if (ep_we)
            eps[ep_wa] <= ep_wd;
    end

    eam01r_core u_r (
        .clk(clk), .rst_n(rst_n),
        .query_start(e1_start), .do_map(e1_map),
        .query_key(qkey), .context_vec(qvec), .context_token(qtok),
        .hit_max(hit_max), .margin_min(margin_min),
        .soft_rst(e1_soft), .clr_stat(e1_clr),
        .idle(e1_idle), .result_valid(e1_rvalid), .hit(e1_hit),
        .out_token(e1_tok), .out_vector(e1_vec), .out_confidence(e1_conf),
        .out_hamming(e1_ham), .out_second(e1_sec), .out_margin(e1_omarg),
        .cand_n(e1_cand), .ovf_n(e1_ovf),
        .hit_cnt(e1_hitc), .miss_cnt(e1_missc), .qry_cnt(e1_qryc),
        .epoch(e1_epoch)
    );

    assign idle = (st == S_IDLE);
    assign teacher_off = teach;
    assign hit_cnt = e1_hitc;
    assign miss_cnt = e1_missc;
    assign qry_cnt = e1_qryc;
    assign cand_n = e1_cand;
    assign ovf_n = e1_ovf;
    assign epoch = e1_epoch;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= S_IDLE;
            teach <= 1'b0;
            alloc <= 8'd0;
            ep_gen <= 8'd1;
            n_open <= 9'd0;
            ep_we <= 1'b0;
            e1_start <= 1'b0;
            e1_map <= 1'b0;
            e1_soft <= 1'b0;
            e1_clr <= 1'b0;
            result_valid <= 1'b0;
            hit <= 1'b0;
            collide <= 1'b0;
            nack <= 1'b0;
            nack_code <= E2M_NACK_OK;
            out_episode <= 8'd0;
            out_token <= 8'd0;
            out_cue_n <= 8'd0;
            out_hamming <= 7'd64;
            out_second <= 7'd64;
            out_margin <= 8'd0;
            got_r <= 1'b0;
        end else begin
            ep_we <= 1'b0;
            e1_start <= 1'b0;
            e1_soft <= 1'b0;
            e1_clr <= 1'b0;
            result_valid <= 1'b0;

            if (soft_rst) begin
                teach <= 1'b0;
                alloc <= 8'd0;
                n_open <= 9'd0;
                ep_gen <= (ep_gen == 8'hFF) ? 8'd1 : (ep_gen + 8'd1);
                e1_soft <= 1'b1;
            end
            if (clr_stat)
                e1_clr <= 1'b1;
            if (teacher_off_cmd)
                teach <= 1'b1;

            unique case (st)
                S_IDLE: begin
                    got_r <= 1'b0;
                    collide <= 1'b0;
                    nack <= 1'b0;
                    nack_code <= E2M_NACK_OK;
                    if (open_start) begin
                        if (teach) begin
                            hit <= 1'b0;
                            nack <= 1'b1;
                            nack_code <= E2M_NACK_TEACH;
                            st <= S_OUT;
                        end else if (n_open >= 9'd256) begin
                            hit <= 1'b0;
                            nack <= 1'b1;
                            nack_code <= E2M_NACK_FULL;
                            st <= S_OUT;
                        end else
                            st <= S_OPEN;
                    end else if (bind_start) begin
                        if (teach) begin
                            hit <= 1'b0;
                            nack <= 1'b1;
                            nack_code <= E2M_NACK_TEACH;
                            st <= S_OUT;
                        end else begin
                            ep_ra <= in_episode;
                            ep_sel <= in_episode;
                            qkey <= in_key;
                            st <= S_BIND_RD;
                        end
                    end else if (probe_start) begin
                        qkey <= in_key;
                        qvec <= '0;
                        qtok <= 8'd0;
                        st <= S_PROBE_ISSUE;
                    end
                end

                S_OPEN: begin
                    ep_wa <= alloc;
                    ep_wd.valid <= 1'b1;
                    ep_wd.gen <= ep_gen;
                    ep_wd.token <= in_token;
                    ep_wd.cue_n <= 8'd0;
                    ep_wd.vec <= in_vec;
                    ep_we <= 1'b1;
                    out_episode <= alloc;
                    out_token <= in_token;
                    out_cue_n <= 8'd0;
                    out_hamming <= 7'd64;
                    out_second <= 7'd64;
                    out_margin <= 8'd0;
                    hit <= 1'b0;
                    n_open <= n_open + 9'd1;
                    if (alloc != 8'hFF)
                        alloc <= alloc + 8'd1;
                    st <= S_OUT;
                end

                S_BIND_RD:   st <= S_BIND_RLAT;
                S_BIND_RLAT: begin
                    ep_lat <= ep_q;
                    if (!e2m_live(ep_q, ep_gen)) begin
                        nack <= 1'b1;
                        nack_code <= E2M_NACK_BADEP;
                        st <= S_OUT;
                    end else
                        st <= S_BIND_ISSUE;
                end

                S_BIND_ISSUE: if (e1_idle) begin
                    qvec <= ep_lat.vec;
                    qtok <= ep_sel;
                    e1_map <= 1'b0;
                    e1_start <= 1'b1;
                    got_r <= 1'b0;
                    st <= S_BIND_WAIT;
                end

                S_BIND_WAIT: begin
                    if (e1_rvalid) begin
                        lat_hit <= e1_hit;
                        lat_tok <= e1_tok;
                        lat_ham <= e1_ham;
                        lat_sec <= e1_sec;
                        lat_marg <= e1_omarg;
                        got_r <= 1'b1;
                    end
                    if (got_r && e1_idle) begin
                        got_r <= 1'b0;
                        out_hamming <= lat_ham;
                        out_second <= lat_sec;
                        out_margin <= lat_marg;
                        if (lat_hit) begin
                            collide <= 1'b1;
                            nack <= 1'b1;
                            nack_code <= E2M_NACK_COLLIDE;
                            out_episode <= lat_tok;
                            out_token <= ep_lat.token;
                            out_cue_n <= ep_lat.cue_n;
                            st <= S_OUT;
                        end else
                            st <= S_BIND_MAP;
                    end
                end

                S_BIND_MAP: if (e1_idle) begin
                    qvec <= ep_lat.vec;
                    qtok <= ep_sel;
                    e1_map <= 1'b1;
                    e1_start <= 1'b1;
                    got_r <= 1'b0;
                    st <= S_BIND_WAITM;
                end

                S_BIND_WAITM: begin
                    if (e1_rvalid) begin
                        lat_hit <= e1_hit;
                        lat_ham <= e1_ham;
                        lat_sec <= e1_sec;
                        lat_marg <= e1_omarg;
                        got_r <= 1'b1;
                    end
                    if (got_r && e1_idle)
                        st <= S_BIND_COMMIT;
                end

                S_BIND_COMMIT: begin
                    ep_wa <= ep_sel;
                    ep_wd.valid <= ep_lat.valid;
                    ep_wd.gen <= ep_lat.gen;
                    ep_wd.token <= ep_lat.token;
                    ep_wd.vec <= ep_lat.vec;
                    ep_wd.cue_n <= (ep_lat.cue_n == 8'hFF) ? 8'hFF : (ep_lat.cue_n + 8'd1);
                    ep_we <= 1'b1;
                    out_episode <= ep_sel;
                    out_token <= ep_lat.token;
                    out_cue_n <= (ep_lat.cue_n == 8'hFF) ? 8'hFF : (ep_lat.cue_n + 8'd1);
                    out_hamming <= lat_ham;
                    out_second <= lat_sec;
                    out_margin <= lat_marg;
                    hit <= 1'b0;
                    st <= S_OUT;
                end

                S_PROBE_ISSUE: if (e1_idle) begin
                    e1_map <= 1'b0;
                    e1_start <= 1'b1;
                    got_r <= 1'b0;
                    st <= S_PROBE_WAIT;
                end

                S_PROBE_WAIT: begin
                    if (e1_rvalid) begin
                        lat_hit <= e1_hit;
                        lat_tok <= e1_tok;
                        lat_ham <= e1_ham;
                        lat_sec <= e1_sec;
                        lat_marg <= e1_omarg;
                        got_r <= 1'b1;
                    end
                    if (got_r && e1_idle) begin
                        got_r <= 1'b0;
                        out_hamming <= lat_ham;
                        out_second <= lat_sec;
                        out_margin <= lat_marg;
                        if (!lat_hit) begin
                            hit <= 1'b0;
                            out_episode <= 8'd0;
                            out_token <= 8'd0;
                            out_cue_n <= 8'd0;
                            st <= S_OUT;
                        end else begin
                            ep_ra <= lat_tok;
                            st <= S_PROBE_RD;
                        end
                    end
                end

                S_PROBE_RD:   st <= S_PROBE_RLAT;
                S_PROBE_RLAT: begin
                    if (!e2m_live(ep_q, ep_gen)) begin
                        hit <= 1'b0;
                        nack <= 1'b1;
                        nack_code <= E2M_NACK_BADEP;
                        out_episode <= lat_tok;
                        out_token <= 8'd0;
                        out_cue_n <= 8'd0;
                    end else begin
                        hit <= 1'b1;
                        out_episode <= lat_tok;
                        out_token <= ep_q.token;
                        out_cue_n <= ep_q.cue_n;
                    end
                    st <= S_OUT;
                end

                S_OUT: begin
                    result_valid <= 1'b1;
                    st <= S_IDLE;
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule
