`timescale 1ns/1ps
import a7eam00_pkg::*;
import a7eam01r_pkg::*;
module tb_a7eam01r;
    logic clk = 0, rst_n = 0;
    always #5 clk = ~clk;

    logic        start, do_map, rvalid, hit, idle;
    logic [63:0] qkey;
    logic [127:0] qvec;
    logic [7:0]  qtok, hit_max, marg, otok, oconf, omarg, epoch;
    logic [6:0]  oham, osec;
    logic [127:0] ovec;
    logic [15:0] ocand, oovf;
    logic [31:0] hit_cnt, miss_cnt, qry_cnt;
    logic        soft_rst, clr_stat;

    eam01r_core u_dut (
        .clk(clk), .rst_n(rst_n),
        .query_start(start), .do_map(do_map),
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

    // Pairwise Hamming ≥ 16 so MARGIN_MIN=4 cannot reject an exact unique hit.
    // byte b of key i: A5 ^ (17*b) ^ (13*i)  — 13 coprime to 256, unique per bank.
    function automatic logic [63:0] sep_key(input int unsigned i);
        logic [63:0] k;
        int b;
        k = '0;
        for (b = 0; b < 8; b++)
            k[8*b +: 8] = 8'hA5 ^ 8'(b * 17) ^ 8'(i * 13);
        return k;
    endfunction

    integer guard;

    task automatic go(input bit map, input [63:0] k, input [7:0] t);
        begin
            @(posedge clk);
            while (!idle) @(posedge clk);
            qkey <= k;
            qvec <= {16{t}};
            qtok <= t;
            do_map <= map;
            start <= 1'b1;
            @(posedge clk);
            start <= 1'b0;
            guard = 0;
            while (!rvalid) begin
                @(posedge clk);
                guard++;
                if (guard > 400000) begin
                    $display("TB_FAIL timeout map=%0d k=%016h", map, k);
                    $finish;
                end
            end
        end
    endtask

    integer i;
    logic [63:0] keys [0:15];
    logic [7:0]  toks [0:15];
    logic [63:0] kflip;

    initial begin
        start = 0;
        do_map = 0;
        soft_rst = 0;
        clr_stat = 0;
        hit_max = 8'd8;
        marg = 8'd4;
        qkey = 0;
        qvec = 0;
        qtok = 0;
        repeat (20) @(posedge clk);
        rst_n = 1;
        repeat (20) @(posedge clk);

        for (i = 0; i < 16; i++) begin
            keys[i] = sep_key(i);
            toks[i] = 8'(8'h30 + i);
            go(1, keys[i], toks[i]);
            if (hit) begin
                $display("TB_FAIL first map should miss i=%0d d=%0d", i, oham);
                $finish;
            end
        end
        if (oovf !== 16'd0) begin
            $display("TB_FAIL unexpected overflow after 16 maps ovf=%0d", oovf);
            $finish;
        end

        for (i = 0; i < 16; i++) begin
            go(0, keys[i], 8'd0);
            if (!hit || otok !== toks[i] || oham !== 7'd0) begin
                $display("TB_FAIL exact i=%0d hit=%0d tok=%0d d=%0d 2nd=%0d m=%0d c=%0d best_id=%0d qkey=%016h rec_key=%016h",
                         i, hit, otok, oham, osec, omarg, ocand, u_dut.best_id, u_dut.qkey, u_dut.rec_key);
                $finish;
            end
        end

        // 00G disease: flip only key[7:0] (INDEX0 bucket). Other 7 banks still nominate.
        kflip = keys[3] ^ 64'h1;
        go(0, kflip, 8'd0);
        if (!hit || otok !== toks[3] || oham !== 7'd1) begin
            $display("TB_FAIL set-byte flip hit=%0d tok=%0d d=%0d 2nd=%0d", hit, otok, oham, osec);
            $finish;
        end

        // 8 flips in one byte (d=8); other bytes exact → found on exact pass.
        kflip = keys[5] ^ 64'hFF;
        go(0, kflip, 8'd0);
        if (!hit || otok !== toks[5] || oham !== 7'd8) begin
            $display("TB_FAIL 8-in-one-byte hit=%0d tok=%0d d=%0d", hit, otok, oham);
            $finish;
        end

        // Theorem case: 1 flip in every byte (d=8). Exact buckets empty;
        // radius-1 must nominate. This is the 00G set-flip failure, distributed.
        kflip = keys[9] ^ 64'h0101010101010101;
        go(0, kflip, 8'd0);
        if (!hit || otok !== toks[9] || oham !== 7'd8) begin
            $display("TB_FAIL theorem 1-per-byte hit=%0d tok=%0d d=%0d 2nd=%0d c=%0d",
                     hit, otok, oham, osec, ocand);
            $finish;
        end

        // 2 bits in every byte → d=16. No byte has d≤1, so r1 must not be
        // required to find it; HIT_MAX=8 rejects even if some other posting hits.
        kflip = keys[7] ^ 64'h0303030303030303;
        go(0, kflip, 8'd0);
        if (hit) begin
            $display("TB_FAIL d16 should reject hit d=%0d tok=%0d", oham, otok);
            $finish;
        end

        go(0, 64'hDEADBEEFCAFEBABE, 8'd0);
        if (hit) begin
            $display("TB_FAIL unrelated hit d=%0d tok=%0d", oham, otok);
            $finish;
        end

        $display("A7EAM01R_XSIM_PASS exact=16 setflip d8 theorem-r1 d16 unrelated ovf=%0d", oovf);
        $finish;
    end
endmodule
