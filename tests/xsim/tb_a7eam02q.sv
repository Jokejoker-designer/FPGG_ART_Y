`timescale 1ns/1ps
import a7eam00_pkg::*;
import a7eam01r_pkg::*;
module tb_a7eam02q;
    `include "a7eam02q_q1_tv.svh"

    logic clk = 0, rst_n = 0;
    always #5 clk = ~clk;

    logic signed [15:0] hmem [0:127];
    logic        start, busy, done;
    logic [6:0]  jj;
    logic [63:0] key;

    eam02q_q1 u_q1 (
        .clk(clk), .rst_n(rst_n),
        .start(start), .h(hmem[jj]), .j(jj),
        .busy(busy), .done(done), .key(key)
    );

    logic        qstart, do_map, rvalid, hit, idle;
    logic [63:0] qkey;
    logic [127:0] qvec;
    logic [7:0]  qtok, hit_max, marg, otok, oconf, omarg, epoch;
    logic [6:0]  oham, osec;
    logic [127:0] ovec;
    logic [15:0] ocand, oovf;
    logic [31:0] hit_cnt, miss_cnt, qry_cnt;
    logic        soft_rst, clr_stat;

    eam01r_core u_mem (
        .clk(clk), .rst_n(rst_n),
        .query_start(qstart), .do_map(do_map),
        .query_key(qkey), .context_vec(qvec), .context_token(qtok),
        .hit_max(hit_max), .margin_min(marg),
        .soft_rst(soft_rst), .clr_stat(clr_stat),
        .idle(idle), .result_valid(rvalid), .hit(hit),
        .out_token(otok), .out_vector(ovec), .out_confidence(oconf),
        .out_hamming(oham), .out_second(osec), .out_margin(omarg),
        .cand_n(ocand), .ovf_n(oovf),
        .hit_cnt(hit_cnt), .miss_cnt(miss_cnt), .qry_cnt(qry_cnt),
        .epoch(epoch)
    );

    integer i, k, guard;

    task automatic enc_one(input int unsigned idx);
        begin
            for (k = 0; k < 128; k++)
                hmem[k] = Q1_TV_H[idx][k];
            @(posedge clk);
            start <= 1'b1;
            @(posedge clk);
            start <= 1'b0;
            guard = 0;
            while (!done) begin
                @(posedge clk);
                guard++;
                if (guard > 400) begin
                    $display("TB_FAIL Q1 timeout idx=%0d", idx);
                    $finish;
                end
            end
            @(posedge clk);
        end
    endtask

    task automatic mem_go(input bit map, input [63:0] kk, input [7:0] t);
        begin
            @(posedge clk);
            while (!idle) @(posedge clk);
            qkey <= kk;
            qvec <= {16{t}};
            qtok <= t;
            do_map <= map;
            qstart <= 1'b1;
            @(posedge clk);
            qstart <= 1'b0;
            guard = 0;
            while (!rvalid) begin
                @(posedge clk);
                guard++;
                if (guard > 400000) begin
                    $display("TB_FAIL mem timeout");
                    $finish;
                end
            end
        end
    endtask

    initial begin
        start = 0;
        qstart = 0;
        do_map = 0;
        soft_rst = 0;
        clr_stat = 0;
        hit_max = 8'd8;
        marg = 8'd4;
        qkey = 0;
        qvec = 0;
        qtok = 0;
        for (k = 0; k < 128; k++)
            hmem[k] = 0;
        repeat (10) @(posedge clk);
        rst_n = 1;
        repeat (10) @(posedge clk);

        for (i = 0; i < Q1_TV_N; i++) begin
            enc_one(i);
            if (key !== Q1_TV_KEY[i]) begin
                $display("TB_FAIL twin i=%0d got=%016h exp=%016h", i, key, Q1_TV_KEY[i]);
                $finish;
            end
        end
        $display("Q1_TWIN_PASS n=%0d", Q1_TV_N);

        enc_one(5);
        mem_go(1, key, 8'hA1);
        if (hit) begin
            $display("TB_FAIL first MAP_H should miss");
            $finish;
        end
        enc_one(5);
        mem_go(0, key, 8'd0);
        if (!hit || otok !== 8'hA1 || oham !== 7'd0) begin
            $display("TB_FAIL encode-then-probe hit=%0d tok=%0d d=%0d", hit, otok, oham);
            $finish;
        end
        enc_one(7);
        mem_go(0, key, 8'd0);
        if (hit) begin
            $display("TB_FAIL far hidden should miss d=%0d", oham);
            $finish;
        end

        $display("A7EAM02Q_XSIM_PASS twin=%0d map_probe far_miss", Q1_TV_N);
        $finish;
    end
endmodule
