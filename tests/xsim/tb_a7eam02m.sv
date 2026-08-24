`timescale 1ns/1ps
import a7eam00_pkg::*;
import a7eam01r_pkg::*;
import a7eam02m_pkg::*;
module tb_a7eam02m;
    logic clk = 0, rst_n = 0;
    always #5 clk = ~clk;

    logic        open_s, bind_s, probe_s, toff, soft_rst, clr_stat;
    logic        idle, rvalid, hit, col, nack, teach;
    logic [7:0]  in_ep, in_tok, ncode, oep, otok, ocue, omarg, epoch;
    logic [63:0] in_key;
    logic [127:0] in_vec;
    logic [7:0]  hit_max, marg;
    logic [6:0]  oham, osec;
    logic [15:0] ocand, oovf;
    logic [31:0] hit_cnt, miss_cnt, qry_cnt;

    eam02m_core u_dut (
        .clk(clk), .rst_n(rst_n),
        .open_start(open_s), .bind_start(bind_s), .probe_start(probe_s),
        .teacher_off_cmd(toff), .soft_rst(soft_rst), .clr_stat(clr_stat),
        .in_episode(in_ep), .in_token(in_tok), .in_key(in_key), .in_vec(in_vec),
        .hit_max(hit_max), .margin_min(marg),
        .idle(idle), .result_valid(rvalid),
        .hit(hit), .collide(col), .nack(nack), .nack_code(ncode),
        .out_episode(oep), .out_token(otok), .out_cue_n(ocue),
        .out_hamming(oham), .out_second(osec), .out_margin(omarg),
        .teacher_off(teach),
        .hit_cnt(hit_cnt), .miss_cnt(miss_cnt), .qry_cnt(qry_cnt),
        .cand_n(ocand), .ovf_n(oovf), .epoch(epoch)
    );

    function automatic logic [63:0] sep_key(input int unsigned i);
        logic [63:0] k;
        int b;
        k = '0;
        for (b = 0; b < 8; b++)
            k[8*b +: 8] = 8'hA5 ^ 8'(b * 17) ^ 8'(i * 13);
        return k;
    endfunction

    function automatic int hd(input logic [63:0] a, input logic [63:0] b);
        return $countones(a ^ b);
    endfunction

    function automatic logic [63:0] far_from4(
        input logic [63:0] a, input logic [63:0] b,
        input logic [63:0] c, input logic [63:0] d
    );
        logic [63:0] k;
        int t;
        k = 64'h0123456789ABCDEF;
        for (t = 0; t < 4096; t++) begin
            if (hd(k, a) >= 24 && hd(k, b) >= 24 && hd(k, c) >= 24 && hd(k, d) >= 24)
                return k;
            k = k + 64'h100000001B3;
        end
        return ~a;
    endfunction

    integer guard;

    task automatic wait_done;
        begin
            guard = 0;
            while (!rvalid) begin
                @(posedge clk);
                guard++;
                if (guard > 800000) begin
                    $display("TB_FAIL timeout");
                    $finish;
                end
            end
        end
    endtask

    task automatic do_open(input [7:0] tok, output [7:0] epid);
        begin
            @(posedge clk);
            while (!idle) @(posedge clk);
            in_tok <= tok;
            in_vec <= {16{tok}};
            open_s <= 1'b1;
            @(posedge clk);
            open_s <= 1'b0;
            wait_done();
            if (nack) begin
                $display("TB_FAIL open nack=%0d", ncode);
                $finish;
            end
            epid = oep;
        end
    endtask

    task automatic do_bind(input [7:0] epid, input [63:0] k);
        begin
            @(posedge clk);
            while (!idle) @(posedge clk);
            in_ep <= epid;
            in_key <= k;
            bind_s <= 1'b1;
            @(posedge clk);
            bind_s <= 1'b0;
            wait_done();
        end
    endtask

    task automatic do_probe(input [63:0] k);
        begin
            @(posedge clk);
            while (!idle) @(posedge clk);
            in_key <= k;
            probe_s <= 1'b1;
            @(posedge clk);
            probe_s <= 1'b0;
            wait_done();
        end
    endtask

    integer i, dAB;
    logic [7:0]  ep0, ep1;
    logic [63:0] ka, kb, kc, kd, kfar, kflip;

    initial begin
        open_s = 0; bind_s = 0; probe_s = 0; toff = 0;
        soft_rst = 0; clr_stat = 0;
        hit_max = 8'd8; marg = 8'd4;
        in_ep = 0; in_tok = 0; in_key = 0; in_vec = 0;
        repeat (20) @(posedge clk);
        rst_n = 1;
        repeat (20) @(posedge clk);

        ka = sep_key(0);
        kb = sep_key(1);
        kc = sep_key(2);
        kd = sep_key(3);
        kfar = far_from4(ka, kb, kc, kd);
        dAB = hd(ka, kb);
        if (dAB < 24 || hd(kfar, ka) < 24) begin
            $display("TB_FAIL key gap A-B=%0d far-A=%0d", dAB, hd(kfar, ka));
            $finish;
        end

        do_open(8'hA7, ep0);
        if (ep0 !== 8'd0) begin
            $display("TB_FAIL first episode %0d", ep0);
            $finish;
        end

        do_bind(ep0, ka);
        if (nack || ocue !== 8'd1) begin
            $display("TB_FAIL bind A nack=%0d cue=%0d", nack, ocue);
            $finish;
        end
        do_bind(ep0, kb);
        if (nack || ocue !== 8'd2 || oep !== ep0) begin
            $display("TB_FAIL bind B nack=%0d cue=%0d ep=%0d", nack, ocue, oep);
            $finish;
        end

        do_open(8'h22, ep1);
        do_bind(ep1, kc);
        do_bind(ep1, kd);
        if (nack || oep !== ep1 || ocue !== 8'd2) begin
            $display("TB_FAIL ep1 bind fail");
            $finish;
        end

        @(posedge clk);
        while (!idle) @(posedge clk);
        toff <= 1'b1;
        @(posedge clk);
        toff <= 1'b0;
        repeat (4) @(posedge clk);

        do_bind(ep0, kfar);
        if (!nack || ncode !== E2M_NACK_TEACH) begin
            $display("TB_FAIL teacher-off bind nack=%0d code=%0d", nack, ncode);
            $finish;
        end

        do_probe(ka);
        if (!hit || oep !== ep0 || otok !== 8'hA7 || oham !== 7'd0) begin
            $display("TB_FAIL probe A hit=%0d ep=%0d tok=%02h d=%0d", hit, oep, otok, oham);
            $finish;
        end
        do_probe(kb);
        if (!hit || oep !== ep0 || otok !== 8'hA7 || oham !== 7'd0) begin
            $display("TB_FAIL probe B hit=%0d ep=%0d tok=%02h d=%0d", hit, oep, otok, oham);
            $finish;
        end
        do_probe(kc);
        if (!hit || oep !== ep1 || otok !== 8'h22) begin
            $display("TB_FAIL probe C crosstalk ep=%0d tok=%02h", oep, otok);
            $finish;
        end

        kflip = ka ^ 64'h1;
        do_probe(kflip);
        if (!hit || oep !== ep0 || otok !== 8'hA7 || oham !== 7'd1) begin
            $display("TB_FAIL 1flip hit=%0d ep=%0d tok=%02h d=%0d", hit, oep, otok, oham);
            $finish;
        end

        do_probe(kfar);
        if (hit) begin
            $display("TB_FAIL unrelated hit ep=%0d d=%0d", oep, oham);
            $finish;
        end

        // collide: same cue rebound after new teacher-on via soft-rst would wipe;
        // collide is tested before teacher-off on a fresh bind of ka — already bound.
        // Re-open path: pulse soft_rst then rebuild one episode and collide.
        @(posedge clk);
        while (!idle) @(posedge clk);
        soft_rst <= 1'b1;
        @(posedge clk);
        soft_rst <= 1'b0;
        repeat (8) @(posedge clk);

        do_open(8'hA7, ep0);
        do_bind(ep0, ka);
        do_bind(ep0, ka);
        if (!nack || ncode !== E2M_NACK_COLLIDE || ocue !== 8'd1) begin
            $display("TB_FAIL collide nack=%0d code=%0d cue=%0d", nack, ncode, ocue);
            $finish;
        end

        $display("A7EAM02M_XSIM_PASS");
        $finish;
    end
endmodule
