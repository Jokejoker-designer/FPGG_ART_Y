`timescale 1ns/1ps
import a7eam03e_pkg::*;
module tb_a7eam03e;
    logic clk = 0, rst_n = 0;
    always #5 clk = ~clk;

    logic        start_seed, start_pair, start_enc, learn, freeze, same, enc_slot;
    logic        idle, rvalid, upd;
    logic [31:0] seed_in, seed_used;
    logic [7:0]  nA, nB;
    logic [7:0]  seqA [0:E3_TMAX-1];
    logic [7:0]  seqB [0:E3_TMAX-1];
    logic [6:0]  dH;
    logic [15:0] d1;
    logic [63:0] cue;

    eam03e_core u_dut (
        .clk(clk), .rst_n(rst_n),
        .start_seed(start_seed), .start_pair(start_pair), .start_enc(start_enc),
        .seed_in(seed_in), .learn(learn), .freeze(freeze),
        .label_same(same), .enc_slot(enc_slot),
        .nA(nA), .nB(nB), .seqA(seqA), .seqB(seqB),
        .idle(idle), .result_valid(rvalid), .updated(upd),
        .dH(dH), .d1(d1), .cue(cue), .seed_used(seed_used)
    );

    integer guard, k;

    task automatic wait_done;
        begin
            guard = 0;
            while (!rvalid) begin
                @(posedge clk);
                guard++;
                if (guard > 2000000) begin
                    $display("TB_FAIL timeout");
                    $finish;
                end
            end
        end
    endtask

    task automatic load_str(input int slot, input string s);
        int i;
        begin
            if (slot == 0) begin
                nA = 8'(s.len());
                for (i = 0; i < E3_TMAX; i++)
                    seqA[i] = (i < s.len()) ? 8'(s[i]) : 8'd0;
            end else begin
                nB = 8'(s.len());
                for (i = 0; i < E3_TMAX; i++)
                    seqB[i] = (i < s.len()) ? 8'(s[i]) : 8'd0;
            end
        end
    endtask

    task automatic do_seed(input [31:0] sd);
        begin
            @(posedge clk);
            while (!idle) @(posedge clk);
            seed_in <= sd;
            start_seed <= 1'b1;
            @(posedge clk);
            start_seed <= 1'b0;
            wait_done();
        end
    endtask

    task automatic do_pair(input bit is_same, output [15:0] od1, output [6:0] odh);
        begin
            @(posedge clk);
            while (!idle) @(posedge clk);
            same <= is_same;
            start_pair <= 1'b1;
            @(posedge clk);
            start_pair <= 1'b0;
            wait_done();
            @(posedge clk);
            od1 = d1;
            odh = dH;
        end
    endtask

    string sA, sB, sC;
    logic [15:0] d_ab0, d_ac0, d_ab1, d_ac1, d_abR, d_ac2, tmp;
    logic [6:0]  htmp;
    integer step;

    initial begin
        start_seed = 0; start_pair = 0; start_enc = 0;
        learn = 0; freeze = 0; same = 0; enc_slot = 0;
        seed_in = E3_SEED0; nA = 0; nB = 0;
        for (k = 0; k < E3_TMAX; k++) begin
            seqA[k] = 0; seqB[k] = 0;
        end
        sA = "ALPHA";
        sB = "BETA.";
        sC = "OMEGA";
        repeat (20) @(posedge clk);
        rst_n = 1;
        repeat (20) @(posedge clk);

        do_seed(32'h11111111);
        learn = 0; freeze = 0;
        load_str(0, sA); load_str(1, sB);
        do_pair(1, tmp, htmp); // prime after seed
        do_pair(1, d_ab0, htmp);
        load_str(1, sC);
        do_pair(0, d_ac0, htmp);
        $display("INIT d1(AB)=%0d d1(AC)=%0d", d_ab0, d_ac0);
        if (d_ab0 !== 16'd3930 || d_ac0 !== 16'd5362) begin
            $display("TB_FAIL A01T golden init AB=%0d AC=%0d", d_ab0, d_ac0);
            $finish;
        end

        learn = 1; freeze = 0;
        for (step = 0; step < 32; step++) begin
            load_str(0, sA); load_str(1, sB);
            do_pair(1, tmp, htmp);
            load_str(0, sA); load_str(1, sC);
            do_pair(0, tmp, htmp);
        end

        learn = 0; freeze = 1;
        load_str(0, sA); load_str(1, sB);
        do_pair(1, d_ab1, htmp);
        load_str(1, sC);
        do_pair(0, d_ac1, htmp);
        $display("TRAIN d1(AB)=%0d d1(AC)=%0d (was %0d %0d)", d_ab1, d_ac1, d_ab0, d_ac0);
        if (d_ab1 !== 16'd1093 || d_ac1 !== 16'd2012) begin
            $display("TB_FAIL A01T golden train AB=%0d AC=%0d", d_ab1, d_ac1);
            $finish;
        end

        if (!(d_ab1 < d_ab0)) begin
            $display("TB_FAIL SAME did not shrink %0d -> %0d", d_ab0, d_ab1);
            $finish;
        end
        if (!(d_ac1 > d_ab1)) begin
            $display("TB_FAIL DIFF not > SAME %0d vs %0d", d_ac1, d_ab1);
            $finish;
        end

        do_seed(32'h11111111);
        learn = 0; freeze = 0;
        load_str(0, sA); load_str(1, sB);
        do_pair(1, d_abR, htmp);
        $display("RESET d1(AB)=%0d (trained was %0d)", d_abR, d_ab1);
        if (d_abR !== 16'd3930) begin
            $display("TB_FAIL A01T golden reset AB=%0d", d_abR);
            $finish;
        end
        if (d_abR <= d_ab1) begin
            $display("TB_FAIL reset did not erase trained SAME");
            $finish;
        end

        learn = 1; freeze = 0;
        for (step = 0; step < 32; step++) begin
            load_str(0, sA); load_str(1, sC);
            do_pair(1, tmp, htmp);
            load_str(0, sA); load_str(1, sB);
            do_pair(0, tmp, htmp);
        end
        learn = 0; freeze = 1;
        load_str(0, sA); load_str(1, sC);
        do_pair(1, d_ac2, htmp);
        load_str(1, sB);
        do_pair(0, d_ab1, htmp);
        $display("SWAP d1(AC)=%0d d1(AB)=%0d", d_ac2, d_ab1);
        if (d_ac2 !== 16'd451 || d_ab1 !== 16'd1574) begin
            $display("TB_FAIL A01T golden swap AC=%0d AB=%0d", d_ac2, d_ab1);
            $finish;
        end
        if (!(d_ac2 < d_ab1)) begin
            $display("TB_FAIL swapped mapping failed");
            $finish;
        end

        $display("A7EAM03EA01T_XSIM_PASS");
        $finish;
    end
endmodule
