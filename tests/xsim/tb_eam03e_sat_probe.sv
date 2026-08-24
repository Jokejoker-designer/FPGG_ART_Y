`timescale 1ns/1ps
// Phase S diagnostic. Reads the internal state array of eam03e_core through a
// hierarchical reference and reports how many coordinates are pinned at the
// positive rail and how many are negative.
//
// Claim under test: the unsigned concatenation at eam03e_core.sv:229 makes the
// state update unsigned, so h can never be negative and rails whenever acc is
// negative. If that is true this probe must report negative == 0 always, with a
// large rail count, on untrained weights.
//
// Diagnostic only. Reads nothing back into the design, changes no law, and is
// not part of the A0.1-T golden ladder.
import a7eam03e_pkg::*;
module tb_eam03e_sat_probe;
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
    integer railed, negative, zero;
    integer total_railed, total_negative, probes;

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

    task automatic do_enc(input int slot);
        begin
            @(posedge clk);
            while (!idle) @(posedge clk);
            enc_slot <= 1'(slot);
            start_enc <= 1'b1;
            @(posedge clk);
            start_enc <= 1'b0;
            wait_done();
            @(posedge clk);
        end
    endtask

    // hierarchical read of the state array after a completed encode
    task automatic probe(input string label);
        begin
            railed = 0; negative = 0; zero = 0;
            for (k = 0; k < 32; k++) begin
                if (u_dut.h[k] == 16'sd32767) railed++;
                if (u_dut.h[k] <  16'sd0)     negative++;
                if (u_dut.h[k] == 16'sd0)     zero++;
            end
            total_railed += railed;
            total_negative += negative;
            probes++;
            $display("PROBE %-16s railed=%0d/32 negative=%0d/32 zero=%0d/32 h0=%0d h1=%0d h2=%0d",
                     label, railed, negative, zero,
                     u_dut.h[0], u_dut.h[1], u_dut.h[2]);
        end
    endtask

    initial begin
        start_seed = 0; start_pair = 0; start_enc = 0;
        learn = 0; freeze = 0; same = 0; enc_slot = 0;
        seed_in = E3_SEED0; nA = 0; nB = 0;
        total_railed = 0; total_negative = 0; probes = 0;
        for (k = 0; k < E3_TMAX; k++) begin
            seqA[k] = 0; seqB[k] = 0;
        end
        repeat (20) @(posedge clk);
        rst_n = 1;
        repeat (20) @(posedge clk);

        do_seed(32'h11111111);
        load_str(0, "ALPHA");  do_enc(0); probe("11111111/ALPHA");
        load_str(0, "BETA.");  do_enc(0); probe("11111111/BETA.");
        load_str(0, "OMEGA");  do_enc(0); probe("11111111/OMEGA");

        do_seed(32'h22222222);
        load_str(0, "ALPHA");  do_enc(0); probe("22222222/ALPHA");
        load_str(0, "OMEGA");  do_enc(0); probe("22222222/OMEGA");

        do_seed(32'hAE7C9805);
        load_str(0, "ALPHA");  do_enc(0); probe("AE7C9805/ALPHA");
        load_str(0, "OMEGA");  do_enc(0); probe("AE7C9805/OMEGA");

        $display("SUMMARY probes=%0d railed_total=%0d negative_total=%0d cells=%0d",
                 probes, total_railed, total_negative, probes * 32);

        if (total_negative != 0) begin
            $display("A7EAM03E_SATPROBE_NEGATIVE_PRESENT");
            $display("state can be negative -- unsigned-update claim is FALSIFIED");
            $finish;
        end
        if (total_railed == 0) begin
            $display("A7EAM03E_SATPROBE_NO_RAIL");
            $finish;
        end
        $display("A7EAM03E_SATPROBE_CONFIRMS_UNSIGNED_RAIL");
        $finish;
    end
endmodule
