`timescale 1ns/1ps
import a7eam00_pkg::*;
// Scan scores 2 ways/cycle through a 3-stage pipe (XOR → popcount → fold).
// Fold keeps only {dist, way, conf, age}. The 256-bit winner is re-fetched
// after the pipe drains so Hamming never fans out into a 256-bit mux
// (that path was WNS −3.46 @ 100 MHz on 00S).
module eam_core (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 query_start,
    input  logic [63:0]          query_key,
    input  logic [127:0]         context_vec,
    input  logic [7:0]           context_token,
    input  logic [7:0]           hit_max,
    input  logic [3:0]           ema_shift,
    input  logic                 auto_update,
    input  logic                 soft_rst,
    input  logic                 clr_stat,
    output logic                 idle,
    output logic                 result_valid,
    output logic                 hit,
    output logic [7:0]           out_token,
    output logic [127:0]         out_vector,
    output logic [7:0]           out_confidence,
    output logic [3:0]           out_way,
    output logic [6:0]           out_hamming,
    output logic [6:0]           out_second,
    output logic [31:0]          hit_cnt,
    output logic [31:0]          miss_cnt,
    output logic [31:0]          qry_cnt,
    output logic [7:0]           epoch,
    output logic [7:0]           last_cycles,
    input  logic                 dbg_fetch,
    input  logic                 dbg_commit,
    input  logic [EAM_AW-1:0]    dbg_index,
    input  logic [255:0]         dbg_wdata,
    output logic [255:0]         dbg_rdata,
    output logic                 dbg_ack
);
    typedef enum logic [2:0] {
        S_IDLE, S_SCAN, S_WAIT, S_LATCH, S_OUT, S_WR, S_DBG_RD, S_DBG_WR
    } st_t;

    st_t st;
    logic [3:0] tick;
    logic [63:0] qkey;
    logic [127:0] qctx;
    logic [7:0]  qtok;
    logic [EAM_SET_W-1:0] qset;
    logic [7:0]  cyc;

    logic        best_ok;
    logic [6:0]  best_d, second_d;
    logic [3:0]  best_w;
    logic [7:0]  best_conf;
    eam_entry_t  best_e;
    logic        inv_ok;
    logic [3:0]  inv_w;
    logic [7:0]  vic_c;
    logic [15:0] vic_age;
    logic [3:0]  vic_w;

    logic        we_a, we_b;
    logic [EAM_AW-1:0] addr_a, addr_b;
    logic [255:0] wdata_a, wdata_b, rdata_a, rdata_b;

    logic        do_hit;
    eam_entry_t  wr_e;
    logic [3:0]  wr_w;

    // Issue / score pipe. KEEP so synth does not collapse XOR+pop+fold.
    // iss → (BRAM updates rdata) bram_v → sample xor → pop ham → fold
    (* keep = "true" *) logic iss_v, bram_v, xor_v, ham_v;
    logic [3:0] way_a_iss, way_b_iss;
    logic [3:0] way_a_b, way_b_b, way_a_x, way_b_x, way_a_h, way_b_h;

    (* keep = "true" *) logic [63:0] xor_a, xor_b;
    logic [7:0]  conf_a_x, conf_b_x;
    logic [15:0] age_a_x, age_b_x;
    logic [15:0] tag_a_x, tag_b_x;
    logic [15:0] flg_a_x, flg_b_x;

    (* keep = "true" *) logic [6:0] ham_a, ham_b;
    (* keep = "true" *) logic val_a, val_b;
    logic [7:0]  conf_a_h, conf_b_h;
    logic [15:0] age_a_h, age_b_h;

    assign idle = (st == S_IDLE);

    eam_tdp256 u_mem (
        .clk(clk),
        .we_a(we_a), .addr_a(addr_a), .wdata_a(wdata_a), .rdata_a(rdata_a),
        .we_b(we_b), .addr_b(addr_b), .wdata_b(wdata_b), .rdata_b(rdata_b)
    );

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= S_IDLE;
            tick <= 4'd0;
            we_a <= 1'b0;
            we_b <= 1'b0;
            addr_a <= '0;
            addr_b <= '0;
            wdata_a <= '0;
            wdata_b <= '0;
            result_valid <= 1'b0;
            hit <= 1'b0;
            out_token <= 8'd0;
            out_vector <= '0;
            out_confidence <= 8'd0;
            out_way <= 4'd0;
            out_hamming <= 7'd64;
            out_second <= 7'd64;
            hit_cnt <= 32'd0;
            miss_cnt <= 32'd0;
            qry_cnt <= 32'd0;
            epoch <= 8'd0;
            last_cycles <= 8'd0;
            dbg_rdata <= '0;
            dbg_ack <= 1'b0;
            best_ok <= 1'b0;
            best_d <= 7'd64;
            second_d <= 7'd64;
            best_w <= 4'd0;
            best_conf <= 8'd0;
            inv_ok <= 1'b0;
            vic_c <= 8'hFF;
            vic_age <= 16'd0;
            vic_w <= 4'd0;
            do_hit <= 1'b0;
            cyc <= 8'd0;
            iss_v <= 1'b0;
            bram_v <= 1'b0;
            xor_v <= 1'b0;
            ham_v <= 1'b0;
            xor_a <= '0;
            xor_b <= '0;
            ham_a <= 7'd0;
            ham_b <= 7'd0;
            val_a <= 1'b0;
            val_b <= 1'b0;
        end else begin
            we_a <= 1'b0;
            we_b <= 1'b0;
            result_valid <= 1'b0;
            dbg_ack <= 1'b0;
            if (soft_rst)
                epoch <= epoch + 8'd1;
            if (clr_stat) begin
                hit_cnt <= 32'd0;
                miss_cnt <= 32'd0;
                qry_cnt <= 32'd0;
            end
            if (st != S_IDLE)
                cyc <= cyc + 8'd1;

            unique case (st)
                S_IDLE: begin
                    iss_v  <= 1'b0;
                    bram_v <= 1'b0;
                    xor_v  <= 1'b0;
                    ham_v  <= 1'b0;
                    if (dbg_fetch) begin
                        addr_a <= dbg_index;
                        st <= S_DBG_RD;
                    end else if (dbg_commit) begin
                        addr_b <= dbg_index;
                        wdata_b <= dbg_wdata;
                        we_b <= 1'b1;
                        st <= S_DBG_WR;
                    end else if (query_start) begin
                        qkey <= query_key;
                        qctx <= context_vec;
                        qtok <= context_token;
                        qset <= eam_set_of(query_key);
                        tick <= 4'd0;
                        best_ok <= 1'b0;
                        best_d <= 7'd64;
                        second_d <= 7'd64;
                        best_w <= 4'd0;
                        best_conf <= 8'd0;
                        inv_ok <= 1'b0;
                        vic_c <= 8'hFF;
                        vic_age <= 16'd0;
                        vic_w <= 4'd0;
                        cyc <= 8'd0;
                        qry_cnt <= qry_cnt + 32'd1;
                        addr_a <= eam_addr(eam_set_of(query_key), 4'd0);
                        addr_b <= eam_addr(eam_set_of(query_key), 4'd1);
                        way_a_iss <= 4'd0;
                        way_b_iss <= 4'd1;
                        iss_v <= 1'b1;
                        st <= S_SCAN;
                    end
                end
                S_SCAN: begin
                    // BRAM rdata updates this cycle for last issue; sample next.
                    bram_v  <= iss_v;
                    way_a_b <= way_a_iss;
                    way_b_b <= way_b_iss;

                    xor_v <= bram_v;
                    if (bram_v) begin
                        xor_a    <= rdata_a[63:0] ^ qkey;
                        xor_b    <= rdata_b[63:0] ^ qkey;
                        conf_a_x <= rdata_a[207:200];
                        conf_b_x <= rdata_b[207:200];
                        age_a_x  <= rdata_a[223:208];
                        age_b_x  <= rdata_b[223:208];
                        tag_a_x  <= rdata_a[239:224];
                        tag_b_x  <= rdata_b[239:224];
                        flg_a_x  <= rdata_a[255:240];
                        flg_b_x  <= rdata_b[255:240];
                        way_a_x  <= way_a_b;
                        way_b_x  <= way_b_b;
                    end

                    ham_v <= xor_v;
                    if (xor_v) begin
                        ham_a    <= eam_pop64(xor_a);
                        ham_b    <= eam_pop64(xor_b);
                        val_a    <= flg_a_x[0] && (tag_a_x[7:0] == epoch);
                        val_b    <= flg_b_x[0] && (tag_b_x[7:0] == epoch);
                        conf_a_h <= conf_a_x;
                        conf_b_h <= conf_b_x;
                        age_a_h  <= age_a_x;
                        age_b_h  <= age_b_x;
                        way_a_h  <= way_a_x;
                        way_b_h  <= way_b_x;
                    end

                    // Stage 3: fold two ways into tiny best/victim regs.
                    if (ham_v) begin
                        logic        bok, iok;
                        logic [6:0]  bd, sd;
                        logic [3:0]  bw, iw, vw;
                        logic [7:0]  bc, vc;
                        logic [15:0] va;
                        bok = best_ok;
                        bd  = best_d;
                        sd  = second_d;
                        bw  = best_w;
                        bc  = best_conf;
                        iok = inv_ok;
                        iw  = inv_w;
                        vc  = vic_c;
                        va  = vic_age;
                        vw  = vic_w;
                        if (val_a) begin
                            if (!bok || ham_a < bd || (ham_a == bd && conf_a_h > bc)) begin
                                if (bok)
                                    sd = bd;
                                bok = 1'b1;
                                bd  = ham_a;
                                bw  = way_a_h;
                                bc  = conf_a_h;
                            end else if (ham_a < sd) begin
                                sd = ham_a;
                            end
                            if (!iok && (conf_a_h < vc || (conf_a_h == vc && age_a_h >= va))) begin
                                vc = conf_a_h;
                                va = age_a_h;
                                vw = way_a_h;
                            end
                        end else if (!iok) begin
                            iok = 1'b1;
                            iw  = way_a_h;
                        end
                        if (val_b) begin
                            if (!bok || ham_b < bd || (ham_b == bd && conf_b_h > bc)) begin
                                if (bok)
                                    sd = bd;
                                bok = 1'b1;
                                bd  = ham_b;
                                bw  = way_b_h;
                                bc  = conf_b_h;
                            end else if (ham_b < sd) begin
                                sd = ham_b;
                            end
                            if (!iok && (conf_b_h < vc || (conf_b_h == vc && age_b_h >= va))) begin
                                vc = conf_b_h;
                                va = age_b_h;
                                vw = way_b_h;
                            end
                        end else if (!iok) begin
                            iok = 1'b1;
                            iw  = way_b_h;
                        end
                        best_ok   <= bok;
                        best_d    <= bd;
                        second_d  <= sd;
                        best_w    <= bw;
                        best_conf <= bc;
                        inv_ok    <= iok;
                        inv_w     <= iw;
                        vic_c     <= vc;
                        vic_age   <= va;
                        vic_w     <= vw;
                    end

                    if (tick < 4'd7) begin
                        addr_a    <= eam_addr(qset, {tick + 4'd1, 1'b0});
                        addr_b    <= eam_addr(qset, {tick + 4'd1, 1'b1});
                        way_a_iss <= {tick + 4'd1, 1'b0};
                        way_b_iss <= {tick + 4'd1, 1'b1};
                        iss_v     <= 1'b1;
                    end else
                        iss_v <= 1'b0;

                    // Last issue tick=6; BRAM tick=7; sample tick=8;
                    // pop tick=9; fold tick=10. Decide tick=11.
                    if (tick == 4'd11) begin
                        iss_v  <= 1'b0;
                        bram_v <= 1'b0;
                        xor_v  <= 1'b0;
                        ham_v  <= 1'b0;
                        // Always re-fetch the winner so 00G can read token
                        // even when d > HIT_MAX (near-miss telemetry).
                        if (best_ok) begin
                            addr_a <= eam_addr(qset, best_w);
                            do_hit <= (best_d <= hit_max[6:0]);
                            st <= S_WAIT;
                        end else begin
                            do_hit <= 1'b0;
                            st <= S_OUT;
                        end
                    end else
                        tick <= tick + 4'd1;
                end
                S_WAIT: begin
                    st <= S_LATCH;
                end
                S_LATCH: begin
                    best_e <= eam_entry_t'(rdata_a);
                    st <= S_OUT;
                end
                S_OUT: begin
                    hit <= do_hit;
                    out_hamming <= best_ok ? best_d : 7'd64;
                    out_second  <= best_ok ? second_d : 7'd64;
                    if (do_hit) begin
                        out_token <= best_e.token;
                        out_vector <= best_e.vec;
                        out_confidence <= best_e.conf;
                        out_way <= best_w;
                        hit_cnt <= hit_cnt + 32'd1;
                        wr_w <= best_w;
                        wr_e.key   <= best_e.key;
                        wr_e.vec   <= eam_ema_vec(best_e.vec, qctx, ema_shift);
                        wr_e.token <= best_e.token;
                        wr_e.conf  <= eam_inc_conf(best_e.conf);
                        wr_e.age   <= eam_inc_age(best_e.age);
                        wr_e.tag   <= best_e.tag;
                        wr_e.flags <= best_e.flags;
                    end else begin
                        out_token <= best_ok ? best_e.token : qtok;
                        out_vector <= best_ok ? best_e.vec : qctx;
                        out_confidence <= best_ok ? best_e.conf : 8'd0;
                        out_way <= best_ok ? best_w : (inv_ok ? inv_w : vic_w);
                        miss_cnt <= miss_cnt + 32'd1;
                        wr_w <= inv_ok ? inv_w : vic_w;
                        wr_e <= eam_new_entry(qkey, qctx, qtok, epoch);
                    end
                    result_valid <= 1'b1;
                    last_cycles <= cyc;
                    st <= auto_update ? S_WR : S_IDLE;
                end
                S_WR: begin
                    addr_b <= eam_addr(qset, wr_w);
                    wdata_b <= wr_e;
                    we_b <= 1'b1;
                    st <= S_IDLE;
                end
                S_DBG_RD: begin
                    dbg_rdata <= rdata_a;
                    dbg_ack <= 1'b1;
                    st <= S_IDLE;
                end
                S_DBG_WR: begin
                    dbg_ack <= 1'b1;
                    st <= S_IDLE;
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule
