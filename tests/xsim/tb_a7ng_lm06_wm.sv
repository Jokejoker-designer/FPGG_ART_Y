`timescale 1ns/1ps
import a7lm06_pkg::*;
//=============================================================================
// lm06_wm_00 equivalence bench.
//
// ONE bench file drives BOTH arms. The only difference between a CONTROL run and
// a CANDIDATE run is which working-set memory file was handed to xvlog:
//
//   CONTROL   rtl/lm/weight_bram803k.sv  act_ram128k16.sv  snap_ram4k16.sv
//   CANDIDATE rtl/native_graph/memory/a7ng_lm06_wm_{wbank,act,snap}.sv
//
// Same module names, same ports, so the frozen arithmetic core
// rtl/lm/tiny_gpt803k_core.sv is literally the same file in both arms and is
// never edited.
//
// HLB R2: this bench never computes an expected token, activation, loss or fold.
// Tier-1 expectations below are TRANSCRIBED from results/A7-LM-06/hardware_c3/
// ladder.json, recorded on silicon 2026-08-18 from frozen bit 222F8043... The
// host oracle python/ref/a7lm06_fixed_ref.py is not invoked anywhere.
//
// HLB R3: EVAL-phase weight writes are proven from per-phase counters on the
// core's own write-enable wwe, not from the absence of a write port.
//
// Run configuration comes from wm00_cfg.txt in the run directory, one value per
// line: tag, nvec, doimg, wmem_path, out_path. A config file is used instead of
// plusargs because the Windows xsim.bat wrapper splits "NAME=value" on '='.
//=============================================================================
module tb_a7ng_lm06_wm;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    always #5 clk = ~clk;

    logic mem_we;
    logic [19:0] mem_addr;
    logic signed [7:0] mem_wdata, mem_rdata;
    logic ctx_we;
    logic [6:0] ctx_idx, ctx_n_in;
    logic [7:0] ctx_bytes [0:7];
    logic [63:0] ctx_pack;
    assign ctx_pack = {ctx_bytes[7], ctx_bytes[6], ctx_bytes[5], ctx_bytes[4],
                       ctx_bytes[3], ctx_bytes[2], ctx_bytes[1], ctx_bytes[0]};
    logic start_fwd, start_train, start_ce, start_corpus;
    logic after_mode, do_snap, do_restore, do_fold;
    logic [9:0] tgt_in;
    logic [3:0] lr_in;
    logic [7:0] corpus_n, corpus_ep;
    logic busy, done;
    logic [9:0] pred;
    logic [15:0] last_loss;
    logic [31:0] ce0, ce1, wr_n, xor32, add32;
    logic [7:0] phase;

    tiny_gpt803k_core u_core (
        .clk(clk), .rst_n(rst_n),
        .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rdata(mem_rdata),
        .ctx_we(ctx_we), .ctx_idx(ctx_idx), .ctx_n_in(ctx_n_in), .ctx_pack(ctx_pack),
        .start_fwd(start_fwd), .start_train(start_train), .start_ce(start_ce),
        .start_corpus(start_corpus), .after_mode(after_mode),
        .do_snap(do_snap), .do_restore(do_restore), .do_fold(do_fold),
        .tgt_in(tgt_in), .lr_in(lr_in), .corpus_n(corpus_n), .corpus_ep(corpus_ep),
        .busy(busy), .done(done), .pred(pred), .last_loss(last_loss),
        .ce0(ce0), .ce1(ce1), .wr_n(wr_n), .xor32(xor32), .add32(add32), .phase(phase)
    );

    //-------------------------------------------------------------------------
    // HLB R3 per-phase write counters.
    // Phase is defined by the window this bench itself commanded, so EVAL is not
    // inferred from a missing port. wwe / awe / snap_we are the core's own write
    // enables and exist identically in both arms.
    //-------------------------------------------------------------------------
    typedef enum int {PH_NONE, PH_UPLOAD, PH_EVAL, PH_TRAIN, PH_AFTER, PH_FOLD, PH_RELOAD} ph_t;
    ph_t cur_ph = PH_NONE;

    int unsigned wr_w   [PH_NONE:PH_RELOAD];
    int unsigned wr_act [PH_NONE:PH_RELOAD];
    int unsigned wr_snp [PH_NONE:PH_RELOAD];

    always_ff @(posedge clk) begin
        if (rst_n) begin
            if (u_core.wwe)     wr_w[cur_ph]   <= wr_w[cur_ph]   + 1;
            if (u_core.awe)     wr_act[cur_ph] <= wr_act[cur_ph] + 1;
            if (u_core.snap_we) wr_snp[cur_ph] <= wr_snp[cur_ph] + 1;
        end
    end

    //-------------------------------------------------------------------------
    // Tier-1 CONTROL, transcribed from hardware_c3/ladder.json (recorded
    // 2026-08-18T19:24:31Z on frozen bit 222F8043...). Not computed here.
    //-------------------------------------------------------------------------
    localparam int T1_PRED  = 744;
    localparam int T1_LOSS  = 16;
    localparam int T1_WRN   = 655616;
    localparam int T1_F0X   = 5;
    localparam int T1_F0A   = 94638317;
    localparam int T1_F1X   = 23;
    localparam int T1_F1A   = 94627297;

    // ladder.json upload_spots[].addr / .got
    localparam int NSPOT = 8;
    int t1_spot_addr [0:NSPOT-1] = '{0, 131072, 147456, 278528, 409600, 540672, 671744, 802808};
    int t1_spot_byte [0:NSPOT-1][0:7] = '{
        '{250, 251, 251, 255, 252,   5,   6,   4},
        '{253,   3,   0,   2,   3,   1,   3, 254},
        '{  4,   0,   2,   5, 255,   3, 255,   4},
        '{255, 254,   4,   6,   5,   6, 251,   4},
        '{  2,   1, 251,   6,   5,   3,   0, 254},
        '{  3, 251,   3,   2,   6, 255, 254, 254},
        '{  6,   6,   2, 255, 254, 254,   5,   5},
        '{253,   4,   6, 252,   0,   0, 252,   0}
    };
    // ladder.json layer_probes[].addr / .got  (post-update, all four layers)
    localparam int NPROBE = 4;
    int t1_probe_addr [0:NPROBE-1] = '{147456, 278528, 409600, 540672};
    int t1_probe_byte [0:NPROBE-1][0:7] = '{
        '{  5, 255,   1,   6, 254,   2, 254,   3},
        '{254, 253,   3,   5,   6,   5, 250,   4},
        '{  3,   2, 252,   7,   4,   4,   1, 253},
        '{  3, 252,   2,   3,   7,   0, 255, 253}
    };

    //-------------------------------------------------------------------------
    // Input vector table. UNIT = one input sequence. Vector 0 is the Tier-1
    // frozen recipe (ctx [1], tgt 32, lr 3) and must run first because the
    // recorded fold0 requires a pristine weight image.
    //-------------------------------------------------------------------------
    localparam int NVEC_MAX = 9;
    int v_ntok [0:NVEC_MAX-1] = '{1, 1, 2, 3, 1, 4, 2, 5, 8};
    int v_tgt  [0:NVEC_MAX-1] = '{32, 100, 5, 200, 1023, 64, 512, 777, 32};
    int v_lr   [0:NVEC_MAX-1] = '{3, 1, 3, 2, 4, 1, 3, 2, 3};
    int v_tok  [0:NVEC_MAX-1][0:7] = '{
        '{  1, 0, 0, 0, 0, 0, 0, 0},
        '{  7, 0, 0, 0, 0, 0, 0, 0},
        '{  1, 7, 0, 0, 0, 0, 0, 0},
        '{  3, 9,17, 0, 0, 0, 0, 0},
        '{255, 0, 0, 0, 0, 0, 0, 0},
        '{  0, 1, 2, 3, 0, 0, 0, 0},
        '{128,64, 0, 0, 0, 0, 0, 0},
        '{ 11,22,33,44,55, 0, 0, 0},
        '{  1, 2, 3, 4, 5, 6, 7, 8}
    };

    logic [7:0] wmem [0:802815];
    logic [7:0] img  [0:802815];
    int nvec, doimg, fails, fd;
    string tag, wmem_path, out_path;
    longint unsigned t_start;

    task automatic step(input int n);
        repeat (n) @(posedge clk);
    endtask

    // Host-port read. host_sel is (st == ST_IDLE) so this is the same path the
    // board's UART 0x31 readback uses, which makes it structure-agnostic.
    task automatic rd1(input int a, output int unsigned d);
        @(posedge clk);
        mem_addr <= a[19:0];
        step(3);
        d = mem_rdata & 8'hFF;
    endtask

    task automatic wait_done(input string what, input int lim);
        int n;
        n = 0;
        while (!done && n < lim) begin
            @(posedge clk);
            n++;
        end
        if (!done) begin
            $display("WM00_FAIL timeout %s phase=%0d n=%0d", what, phase, n);
            $display("WM00_RUN_FAIL");
            $finish;
        end
        @(posedge clk);
    endtask

    task automatic set_ctx(input int v);
        int i;
        @(posedge clk);
        for (i = 0; i < 8; i = i + 1) ctx_bytes[i] <= 8'(v_tok[v][i]);
        ctx_we  <= 1'b1;
        ctx_idx <= 7'd0;
        ctx_n_in <= 7'(v_ntok[v]);
        @(posedge clk);
        ctx_we <= 1'b0;
        @(posedge clk);
    endtask

    task automatic run_fold(output int unsigned fx, output int unsigned fa);
        cur_ph = PH_FOLD;
        @(posedge clk); do_fold <= 1'b1;
        @(posedge clk); do_fold <= 1'b0;
        wait_done("fold", 32_000_000);
        fx = xor32;
        fa = add32;
        cur_ph = PH_NONE;
    endtask

    int unsigned f0x, f0a, f1x, f1a, fRx, fRa;
    int unsigned d;
    int i, v, s, p, bad;
    int unsigned wrn_seq [0:NVEC_MAX-1];
    int unsigned prd_seq [0:NVEC_MAX-1];
    int unsigned lss_seq [0:NVEC_MAX-1];
    int unsigned fx_seq  [0:NVEC_MAX-1];
    int unsigned fa_seq  [0:NVEC_MAX-1];
    int unsigned wr_w_after_probe;

    initial begin
        mem_we = 1'b0; mem_addr = 20'd0; mem_wdata = 8'sd0;
        ctx_we = 1'b0; ctx_idx = 7'd0; ctx_n_in = 7'd0;
        start_fwd = 1'b0; start_train = 1'b0; start_ce = 1'b0; start_corpus = 1'b0;
        after_mode = 1'b0; do_snap = 1'b0; do_restore = 1'b0; do_fold = 1'b0;
        tgt_in = 10'd32; lr_in = 4'd3; corpus_n = 8'd8; corpus_ep = 8'd24;
        for (i = 0; i < 8; i = i + 1) ctx_bytes[i] = 8'd0;
        for (i = PH_NONE; i <= PH_RELOAD; i = i + 1) begin
            wr_w[i] = 0; wr_act[i] = 0; wr_snp[i] = 0;
        end
        fails = 0;

        fd = $fopen("wm00_cfg.txt", "r");
        if (fd == 0) begin
            $display("WM00_FAIL missing wm00_cfg.txt");
            $display("A7NG_LM06_WM00_RUN_FAIL cfg");
            $finish;
        end
        void'($fscanf(fd, "%s\n", tag));
        void'($fscanf(fd, "%d\n", nvec));
        void'($fscanf(fd, "%d\n", doimg));
        void'($fscanf(fd, "%s\n", wmem_path));
        void'($fscanf(fd, "%s\n", out_path));
        $fclose(fd);
        if (out_path == "none") out_path = "";
        if (nvec < 1) nvec = 1;
        if (nvec > NVEC_MAX) nvec = NVEC_MAX;

        $display("WM00_ARM tag=%s nvec=%0d doimg=%0d wmem=%s", tag, nvec, doimg, wmem_path);
`ifdef A7NG_WM_ENFORCE_ACT
        $display("WM00_MODE enforce_act=1");
`else
        $display("WM00_MODE enforce_act=0");
`endif
`ifdef A7NG_WM_ENFORCE_SNAP
        $display("WM00_MODE enforce_snap=1");
`else
        $display("WM00_MODE enforce_snap=0");
`endif

        $readmemh(wmem_path, wmem);

        step(8);
        rst_n = 1'b1;
        step(4);

        //---------------------------------------------------------------- upload
        cur_ph = PH_UPLOAD;
        for (i = 0; i < NPARAM; i = i + 1) begin
            @(posedge clk);
            mem_we <= 1'b1;
            mem_addr <= i[19:0];
            mem_wdata <= wmem[i];
        end
        @(posedge clk);
        mem_we <= 1'b0;
        mem_addr <= 20'd0;
        step(4);
        cur_ph = PH_NONE;
        if (mem_rdata !== wmem[0]) begin
            $display("WM00_FAIL readback0 got=%0d exp=%0d", mem_rdata, wmem[0]);
            fails++;
        end
        $display("WM00_UPLOAD done nparam=%0d", NPARAM);

        //-------------------------------------------------- A10 recorded spots
        bad = 0;
        for (s = 0; s < NSPOT; s = s + 1) begin
            for (p = 0; p < 8; p = p + 1) begin
                rd1(t1_spot_addr[s] + p, d);
                if (d != t1_spot_byte[s][p]) begin
                    $display("WM00_FAIL spot s=%0d addr=%0d off=%0d got=%0d rec=%0d",
                             s, t1_spot_addr[s], p, d, t1_spot_byte[s][p]);
                    bad++;
                end
            end
        end
        $display("WM00_AXIS A10 upload_spots nspot=%0d bad=%0d", NSPOT, bad);
        if (bad != 0) fails++;

        //------------------------------------------------------ per-sequence loop
        for (v = 0; v < nvec; v = v + 1) begin
            set_ctx(v);

            // EVAL phase: forward only, no weight write is legal here.
            cur_ph = PH_EVAL;
            @(posedge clk);
            start_fwd <= 1'b1; tgt_in <= 10'(v_tgt[v]);
            @(posedge clk);
            start_fwd <= 1'b0;
            wait_done($sformatf("fwd v=%0d", v), 200_000_000);
            cur_ph = PH_NONE;
            prd_seq[v] = pred;
            lss_seq[v] = last_loss;
            $display("WM00_SEQ v=%0d pred=%0d loss=%0d wr_n=%0d", v, pred, last_loss, wr_n);

            if (v == 0) begin
                run_fold(f0x, f0a);
                $display("WM00_AXIS A5 fold0 xor=%0d add=%0d", f0x, f0a);
            end

            // TRAIN phase.
            set_ctx(v);
            cur_ph = PH_TRAIN;
            @(posedge clk);
            start_train <= 1'b1; tgt_in <= 10'(v_tgt[v]); lr_in <= 4'(v_lr[v]);
            @(posedge clk);
            start_train <= 1'b0;
            wait_done($sformatf("train v=%0d", v), 400_000_000);
            cur_ph = PH_NONE;
            wrn_seq[v] = wr_n;

            run_fold(f1x, f1a);
            fx_seq[v] = f1x;
            fa_seq[v] = f1a;
            $display("WM00_SEQ v=%0d wr_n=%0d fold_xor=%0d fold_add=%0d", v, wr_n, f1x, f1a);

            if (v == 0) begin
                //-------------------------------- A4 / A6 / A7 vs Tier-1 record
                if (prd_seq[0] != T1_PRED || lss_seq[0] != T1_LOSS) begin
                    $display("WM00_FAIL A4 pred/loss got=%0d/%0d rec=%0d/%0d",
                             prd_seq[0], lss_seq[0], T1_PRED, T1_LOSS);
                    fails++;
                end
                $display("WM00_AXIS A4 pred=%0d rec=%0d loss=%0d rec=%0d",
                         prd_seq[0], T1_PRED, lss_seq[0], T1_LOSS);
                if (f0x != T1_F0X || f0a != T1_F0A) begin
                    $display("WM00_FAIL A5 fold0 got=%0d/%0d rec=%0d/%0d", f0x, f0a, T1_F0X, T1_F0A);
                    fails++;
                end
                if (wrn_seq[0] != T1_WRN) begin
                    $display("WM00_FAIL A6 wr_n got=%0d rec=%0d", wrn_seq[0], T1_WRN);
                    fails++;
                end
                $display("WM00_AXIS A6 wr_n=%0d rec=%0d", wrn_seq[0], T1_WRN);
                if (f1x != T1_F1X || f1a != T1_F1A) begin
                    $display("WM00_FAIL A7 fold1 got=%0d/%0d rec=%0d/%0d", f1x, f1a, T1_F1X, T1_F1A);
                    fails++;
                end
                $display("WM00_AXIS A7 fold1 xor=%0d rec=%0d add=%0d rec=%0d",
                         f1x, T1_F1X, f1a, T1_F1A);

                //-------------------------- A6b recorded per-layer probe windows
                bad = 0;
                for (s = 0; s < NPROBE; s = s + 1) begin
                    for (p = 0; p < 8; p = p + 1) begin
                        rd1(t1_probe_addr[s] + p, d);
                        if (d != t1_probe_byte[s][p]) begin
                            $display("WM00_FAIL probe ly=%0d addr=%0d off=%0d got=%0d rec=%0d",
                                     s, t1_probe_addr[s], p, d, t1_probe_byte[s][p]);
                            bad++;
                        end
                    end
                end
                $display("WM00_AXIS A6b layer_probes nprobe=%0d bad=%0d", NPROBE, bad);
                if (bad != 0) fails++;

                //------------------------------- HLB R3 AFTER-mode zero-write gate
                wr_w_after_probe = wr_w[PH_AFTER];
                set_ctx(0);
                cur_ph = PH_AFTER;
                @(posedge clk);
                after_mode <= 1'b1;
                start_fwd  <= 1'b1; tgt_in <= 10'(v_tgt[0]);
                @(posedge clk);
                start_fwd <= 1'b0;
                wait_done("after_fwd", 200_000_000);
                @(posedge clk);
                after_mode <= 1'b0;
                cur_ph = PH_NONE;
                $display("WM00_AXIS R3_AFTER wr_w_after=%0d (rec: wr_n unchanged)",
                         wr_w[PH_AFTER] - wr_w_after_probe);
                if ((wr_w[PH_AFTER] - wr_w_after_probe) != 0) begin
                    $display("WM00_FAIL R3 AFTER weight writes nonzero");
                    fails++;
                end
            end
        end

        //------------------------------------- A9 / A8 full image + persist round trip
        if (doimg != 0) begin
            for (i = 0; i < NPARAM; i = i + 1) begin
                rd1(i, d);
                img[i] = d[7:0];
            end
            $display("WM00_AXIS A9 image_readback n=%0d", NPARAM);
            if (out_path != "") begin
                fd = $fopen(out_path, "w");
                for (i = 0; i < NPARAM; i = i + 1) $fwrite(fd, "%02x\n", img[i]);
                $fclose(fd);
                $display("WM00_IMG wrote %s", out_path);
            end
            // Persist/reload semantics: flush the whole working set out through
            // the host port and write every byte back, then re-fold. Same shape
            // as the recorded 802816-byte persist flush + reload + fold_reload.
            cur_ph = PH_RELOAD;
            for (i = 0; i < NPARAM; i = i + 1) begin
                @(posedge clk);
                mem_we <= 1'b1;
                mem_addr <= i[19:0];
                mem_wdata <= img[i];
            end
            @(posedge clk);
            mem_we <= 1'b0;
            step(4);
            cur_ph = PH_NONE;
            run_fold(fRx, fRa);
            $display("WM00_AXIS A8 persist_reload_fold xor=%0d add=%0d (must equal last fold %0d/%0d)",
                     fRx, fRa, fx_seq[nvec-1], fa_seq[nvec-1]);
            if (fRx != fx_seq[nvec-1] || fRa != fa_seq[nvec-1]) begin
                $display("WM00_FAIL A8 reload fold diverged");
                fails++;
            end
        end

        //------------------------------------------------------------ counters
        $display("WM00_CNT wr_w   upload=%0d eval=%0d train=%0d after=%0d fold=%0d reload=%0d",
                 wr_w[PH_UPLOAD], wr_w[PH_EVAL], wr_w[PH_TRAIN], wr_w[PH_AFTER],
                 wr_w[PH_FOLD], wr_w[PH_RELOAD]);
        $display("WM00_CNT wr_act upload=%0d eval=%0d train=%0d after=%0d fold=%0d reload=%0d",
                 wr_act[PH_UPLOAD], wr_act[PH_EVAL], wr_act[PH_TRAIN], wr_act[PH_AFTER],
                 wr_act[PH_FOLD], wr_act[PH_RELOAD]);
        $display("WM00_CNT wr_snp upload=%0d eval=%0d train=%0d after=%0d fold=%0d reload=%0d",
                 wr_snp[PH_UPLOAD], wr_snp[PH_EVAL], wr_snp[PH_TRAIN], wr_snp[PH_AFTER],
                 wr_snp[PH_FOLD], wr_snp[PH_RELOAD]);

        if (wr_w[PH_EVAL] != 0) begin
            $display("WM00_FAIL R3 EVAL weight writes = %0d (must be 0)", wr_w[PH_EVAL]);
            fails++;
        end
        $display("WM00_AXIS R3_EVAL wr_w_eval=%0d", wr_w[PH_EVAL]);

        // Per-sequence summary, machine-readable, for cross-arm diff.
        for (v = 0; v < nvec; v = v + 1)
            $display("WM00_ROW v=%0d ntok=%0d tgt=%0d lr=%0d pred=%0d loss=%0d wr_n=%0d fx=%0d fa=%0d",
                     v, v_ntok[v], v_tgt[v], v_lr[v], prd_seq[v], lss_seq[v],
                     wrn_seq[v], fx_seq[v], fa_seq[v]);

        //------------------------------------- working-set residency measurement
`ifdef A7NG_WM_CAND
        $display("WM00_WS w   pp_swaps=%0d live_pair_events=%0d max_live_per_cycle=%0d",
                 u_core.u_w.FULL.u_full.wm_pp_swaps,
                 u_core.u_w.FULL.u_full.wm_live_pair_events,
                 u_core.u_w.FULL.u_full.wm_max_live_per_cycle);
`ifndef A7NG_WM_ENFORCE_ACT
        $display("WM00_WS act pp_swaps=%0d live_pair_events=%0d max_live_per_cycle=%0d",
                 u_core.u_a.wm_pp_swaps, u_core.u_a.wm_live_pair_events,
                 u_core.u_a.wm_max_live_per_cycle);
`else
        $display("WM00_WS act ENFORCED evict_writebacks=%0d refills=%0d pp_swaps=%0d",
                 u_core.u_a.wm_evict_writebacks, u_core.u_a.wm_refills, u_core.u_a.wm_pp_swaps);
`endif
`ifndef A7NG_WM_ENFORCE_SNAP
        $display("WM00_WS snp pp_swaps=%0d live_pair_events=%0d max_live_per_cycle=%0d",
                 u_core.u_snap.wm_pp_swaps, u_core.u_snap.wm_live_pair_events,
                 u_core.u_snap.wm_max_live_per_cycle);
`else
        $display("WM00_WS snp ENFORCED evict_writebacks=%0d refills=%0d pp_swaps=%0d",
                 u_core.u_snap.wm_evict_writebacks, u_core.u_snap.wm_refills,
                 u_core.u_snap.wm_pp_swaps);
`endif
`endif

        if (fails == 0)
            $display("A7NG_LM06_WM00_RUN_PASS tag=%s nvec=%0d fails=0", tag, nvec);
        else
            $display("A7NG_LM06_WM00_RUN_FAIL tag=%s nvec=%0d fails=%0d", tag, nvec, fails);
        $finish;
    end
endmodule
