`timescale 1ns/1ps
import a7eam00_pkg::*;
import a7eam01r_pkg::*;
// Multi-index router. Indexes nominate; Hamming + margin decide HIT.
// Index never declares a hit. No full-scan of 4096 keys.
module eam01r_core (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         query_start,
    input  logic         do_map,
    input  logic [63:0]  query_key,
    input  logic [127:0] context_vec,
    input  logic [7:0]   context_token,
    input  logic [7:0]   hit_max,
    input  logic [7:0]   margin_min,
    input  logic         soft_rst,
    input  logic         clr_stat,
    output logic         idle,
    output logic         result_valid,
    output logic         hit,
    output logic [7:0]   out_token,
    (* keep = "true" *) output logic [127:0] out_vector,
    output logic [7:0]   out_confidence,
    output logic [6:0]   out_hamming,
    output logic [6:0]   out_second,
    output logic [7:0]   out_margin,
    output logic [15:0]  cand_n,
    output logic [15:0]  ovf_n,
    output logic [31:0]  hit_cnt,
    output logic [31:0]  miss_cnt,
    output logic [31:0]  qry_cnt,
    output logic [7:0]   epoch
);
    typedef enum logic [3:0] {
        S_IDLE, S_WR, S_ISCAN, S_IWAIT,
        S_SLOT, S_SLAT, S_BANK, S_SWAIT, S_SEEN, S_RLAT, S_FLAT, S_POP, S_CMP,
        S_DECIDE, S_OUT
    } st_t;

    st_t st;
    logic        mapping;
    logic [63:0] qkey;
    logic [127:0] qvec;
    logic [7:0]  qtok;
    logic [7:0]  qid;
    logic [11:0] alloc, wr_id, best_id;
    logic [2:0]  ibank, sbank;
    logic [4:0]  islot, qslot;
    logic [2:0]  r1bit;
    logic        r1pass, did_ins;
    logic [15:0] cands, ovfs;
    logic        best_ok;
    logic [6:0]  best_d, second_d, pop_q;
    logic [7:0]  best_tok, best_conf;
    logic [127:0] best_vec;
    logic [63:0]  rec_key;
    eam_entry_t  rec_e, wr_e, best_e;

    logic        rec_we;
    logic [11:0] rec_waddr, rec_ra, rec_rb;
    logic [255:0] rec_wdata, rec_da, rec_db;

    eam_tdp256 u_rec (
        .clk(clk),
        .we_a(1'b0), .addr_a(rec_ra), .wdata_a('0), .rdata_a(rec_da),
        .we_b(rec_we), .addr_b(rec_we ? rec_waddr : rec_rb),
        .wdata_b(rec_wdata), .rdata_b(rec_db)
    );

    logic        idx_we [0:7];
    logic [12:0] idx_wa, idx_ra [0:7];
    logic [12:0] idx_da [0:7], idx_wd;

    genvar gi;
    generate
        for (gi = 0; gi < 8; gi++) begin : G_IDX
            eam01r_ibank u_ib (
                .clk(clk),
                .we(idx_we[gi]), .waddr(idx_wa), .wdata(idx_wd),
                .raddr_a(idx_ra[gi]), .raddr_b('0),
                .rdata_a(idx_da[gi]), .rdata_b()
            );
        end
    endgenerate

    (* ram_style = "block" *) logic [7:0] seen [0:4095];
    logic [11:0] seen_a;
    logic [7:0]  seen_q;
    logic        seen_we;
    logic [7:0]  seen_wd;

    integer si;
    initial begin
        for (si = 0; si < 4096; si = si + 1)
            seen[si] = 8'd0;
    end

    always_ff @(posedge clk) begin
        seen_q <= seen[seen_a];
        if (seen_we)
            seen[seen_a] <= seen_wd;
    end

    function automatic logic [7:0] buck_of(input int unsigned b);
        logic [7:0] s;
        s = qkey[8*b +: 8];
        if (r1pass)
            s = s ^ (8'h1 << r1bit);
        return s;
    endfunction

    function automatic logic accept_now;
        logic [7:0] m;
        if (!best_ok)
            return 1'b0;
        if (best_d > hit_max[6:0])
            return 1'b0;
        m = {1'b0, second_d} - {1'b0, best_d};
        return (m >= margin_min);
    endfunction

    assign idle = (st == S_IDLE);
    assign ovf_n = ovfs;

    integer bi;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= S_IDLE;
            mapping <= 1'b0;
            qid <= 8'd1;
            alloc <= 12'd0;
            ibank <= 3'd0;
            islot <= 5'd0;
            qslot <= 5'd0;
            sbank <= 3'd0;
            r1bit <= 3'd0;
            r1pass <= 1'b0;
            result_valid <= 1'b0;
            hit <= 1'b0;
            out_token <= 8'd0;
            out_vector <= '0;
            out_confidence <= 8'd0;
            out_hamming <= 7'd64;
            out_second <= 7'd64;
            out_margin <= 8'd0;
            cand_n <= 16'd0;
            ovfs <= 16'd0;
            hit_cnt <= 32'd0;
            miss_cnt <= 32'd0;
            qry_cnt <= 32'd0;
            epoch <= 8'd0;
            rec_we <= 1'b0;
            seen_we <= 1'b0;
            best_ok <= 1'b0;
            best_d <= 7'd64;
            second_d <= 7'd64;
            did_ins <= 1'b0;
            for (bi = 0; bi < 8; bi++)
                idx_we[bi] <= 1'b0;
        end else begin
            rec_we <= 1'b0;
            seen_we <= 1'b0;
            result_valid <= 1'b0;
            for (bi = 0; bi < 8; bi++)
                idx_we[bi] <= 1'b0;
            if (soft_rst)
                epoch <= epoch + 8'd1;
            if (clr_stat) begin
                hit_cnt <= 32'd0;
                miss_cnt <= 32'd0;
                qry_cnt <= 32'd0;
                ovfs <= 16'd0;
            end

            unique case (st)
                S_IDLE: begin
                    if (query_start) begin
                        qkey <= query_key;
                        qvec <= context_vec;
                        qtok <= context_token;
                        mapping <= do_map;
                        qid <= (qid == 8'hFF) ? 8'd1 : (qid + 8'd1);
                        qry_cnt <= qry_cnt + 32'd1;
                        best_ok <= 1'b0;
                        best_d <= 7'd64;
                        second_d <= 7'd64;
                        cands <= 16'd0;
                        r1pass <= 1'b0;
                        r1bit <= 3'd0;
                        did_ins <= 1'b0;
                        qslot <= 5'd0;
                        sbank <= 3'd0;
                        st <= S_SLOT;
                    end
                end

                // Insert: first empty slot in this bank, else overflow that bank only.
                S_WR: begin
                    islot <= 5'd0;
                    idx_ra[ibank] <= e1_idx_addr(qkey[8*ibank +: 8], 5'd0);
                    st <= S_IWAIT;
                end
                S_ISCAN: begin
                    idx_ra[ibank] <= e1_idx_addr(qkey[8*ibank +: 8], islot);
                    st <= S_IWAIT;
                end
                S_IWAIT: begin
                    if (idx_da[ibank][12] !== 1'b1) begin
                        idx_wa <= e1_idx_addr(qkey[8*ibank +: 8], islot);
                        idx_wd <= {1'b1, wr_id};
                        idx_we[ibank] <= 1'b1;
                        if (ibank == 3'd7)
                            st <= S_IDLE;
                        else begin
                            ibank <= ibank + 3'd1;
                            st <= S_WR;
                        end
                    end else if (islot == 5'd31) begin
                        ovfs <= ovfs + 16'd1;
                        if (ibank == 3'd7)
                            st <= S_IDLE;
                        else begin
                            ibank <= ibank + 3'd1;
                            st <= S_WR;
                        end
                    end else begin
                        islot <= islot + 5'd1;
                        st <= S_ISCAN;
                    end
                end

                // Query: 8 banks in parallel for one slot, then walk valid IDs.
                S_SLOT: begin
                    for (bi = 0; bi < 8; bi++)
                        idx_ra[bi] <= e1_idx_addr(buck_of(bi), qslot);
                    st <= S_SLAT;
                end
                S_SLAT: begin
                    sbank <= 3'd0;
                    st <= S_BANK;
                end
                S_BANK: begin
                    if (idx_da[sbank][12] === 1'b1) begin
                        seen_a <= idx_da[sbank][11:0];
                        wr_id  <= idx_da[sbank][11:0];
                        st <= S_SWAIT;
                    end else if (sbank == 3'd7)
                        st <= S_DECIDE;
                    else
                        sbank <= sbank + 3'd1;
                end
                S_SWAIT: begin
                    st <= S_SEEN;
                end
                S_SEEN: begin
                    if (seen_q == qid) begin
                        if (sbank == 3'd7)
                            st <= S_DECIDE;
                        else begin
                            sbank <= sbank + 3'd1;
                            st <= S_BANK;
                        end
                    end else begin
                        seen_we <= 1'b1;
                        seen_wd <= qid;
                        rec_ra <= wr_id;
                        rec_rb <= wr_id;
                        st <= S_RLAT;
                    end
                end
                S_RLAT: begin
                    st <= S_FLAT;
                end
                S_FLAT: begin
                    rec_e <= eam_entry_t'(rec_da);
                    rec_key <= rec_da[63:0];
                    st <= S_POP;
                end
                S_POP: begin
                    pop_q <= eam_pop64(rec_key ^ qkey);
                    st <= S_CMP;
                end
                S_CMP: begin
                    if (eam_valid_of(rec_e, epoch)) begin
                        cands <= cands + 16'd1;
                        if (!best_ok || pop_q < best_d) begin
                            if (best_ok)
                                second_d <= best_d;
                            best_ok <= 1'b1;
                            best_d <= pop_q;
                            best_id <= wr_id;
                            best_tok <= rec_e.token;
                            best_conf <= rec_e.conf;
                            best_vec <= rec_e.vec;
                            best_e <= rec_e;
                        end else if (pop_q < second_d)
                            second_d <= pop_q;
                    end
                    if (sbank == 3'd7)
                        st <= S_DECIDE;
                    else begin
                        sbank <= sbank + 3'd1;
                        st <= S_BANK;
                    end
                end

                S_DECIDE: begin
                    if (qslot != 5'd31) begin
                        qslot <= qslot + 5'd1;
                        st <= S_SLOT;
                    end else if (accept_now())
                        st <= S_OUT;
                    else if (!r1pass) begin
                        r1pass <= 1'b1;
                        r1bit <= 3'd0;
                        qslot <= 5'd0;
                        st <= S_SLOT;
                    end else if (r1bit != 3'd7) begin
                        r1bit <= r1bit + 3'd1;
                        qslot <= 5'd0;
                        st <= S_SLOT;
                    end else
                        st <= S_OUT;
                end

                S_OUT: begin
                    cand_n <= cands;
                    // Keep we/addr stable this cycle so TDP samples them next edge.
                    if (accept_now()) begin
                        hit <= 1'b1;
                        out_token <= best_tok;
                        out_vector <= best_vec;
                        out_confidence <= best_conf;
                        out_hamming <= best_d;
                        out_second <= second_d;
                        out_margin <= {1'b0, second_d} - {1'b0, best_d};
                        hit_cnt <= hit_cnt + 32'd1;
                        if (mapping) begin
                            wr_e = best_e;
                            wr_e.vec  = eam_ema_vec(best_vec, qvec, 4'd2);
                            wr_e.conf = eam_inc_conf(best_conf);
                            wr_e.age  = eam_inc_age(best_e.age);
                            rec_waddr <= best_id;
                            rec_wdata <= wr_e;
                            rec_we <= 1'b1;
                        end
                        result_valid <= 1'b1;
                        st <= S_IDLE;
                    end else if (mapping && !did_ins) begin
                        did_ins <= 1'b1;
                        wr_id <= alloc;
                        alloc <= alloc + 12'd1;
                        wr_e <= eam_new_entry(qkey, qvec, qtok, epoch);
                        rec_waddr <= alloc;
                        rec_wdata <= eam_new_entry(qkey, qvec, qtok, epoch);
                        rec_we <= 1'b1;
                        ibank <= 3'd0;
                        islot <= 5'd0;
                        hit <= 1'b0;
                        out_token <= qtok;
                        out_vector <= qvec;
                        out_confidence <= 8'd0;
                        out_hamming <= best_ok ? best_d : 7'd64;
                        out_second <= best_ok ? second_d : 7'd64;
                        out_margin <= 8'd0;
                        miss_cnt <= miss_cnt + 32'd1;
                        result_valid <= 1'b1;
                        st <= S_WR;
                    end else begin
                        hit <= 1'b0;
                        out_token <= best_ok ? best_tok : qtok;
                        out_vector <= best_ok ? best_vec : qvec;
                        out_confidence <= 8'd0;
                        out_hamming <= best_ok ? best_d : 7'd64;
                        out_second <= best_ok ? second_d : 7'd64;
                        out_margin <= best_ok ? ({1'b0, second_d} - {1'b0, best_d}) : 8'd0;
                        miss_cnt <= miss_cnt + 32'd1;
                        result_valid <= 1'b1;
                        st <= S_IDLE;
                    end
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule
