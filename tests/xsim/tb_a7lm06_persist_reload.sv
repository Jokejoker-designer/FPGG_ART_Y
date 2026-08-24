`timescale 1ns/1ps
import a7lm06_pkg::*;
// C2: persist reload must finish when the tile is parked on HEAD (miss TOK).
// Mock MIG ignores go-while-busy, matching ddr_tile_dma.
// Pass gate is 2 chunks + one tile-miss refill, not the full 802816
// (silicon ladder is the full-size close).
module tb_a7lm06_persist_reload;
    logic clk50 = 0, clk_ui = 0, rst50_n = 0, rst_ui_n = 0;
    always #10 clk50 = ~clk50;
    always #6 clk_ui = ~clk_ui;

    logic go_flush = 0, go_reload = 0;
    logic p_busy, p_done, p_we, p_stall, p_owner, p_mem_sel;
    logic [19:0] p_addr;
    logic signed [7:0] p_wdata, p_rdata;
    logic [31:0] p_bytes;
    logic p_go, p_wr, p_w_valid, p_w_ready, p_r_valid, p_r_ready;
    logic [27:0] p_dma_addr;
    logic [31:0] p_dma_bytes;
    logic [127:0] p_w_data, p_r_data;
    logic [3:0] dbg_p_bst;
    logic [2:0] dbg_p_dst;
    logic [12:0] dbg_p_ch;
    logic dbg_p_flush, dbg_p_req;

    logic t_we, t_stall, t_owner, t_go, t_wr, t_w_valid, t_w_ready, t_r_valid, t_r_ready;
    logic [19:0] t_addr;
    logic signed [7:0] t_wdata, t_rdata, t_rdb;
    logic [27:0] t_dma_addr;
    logic [31:0] t_dma_bytes;
    logic [127:0] t_w_data, t_r_data;
    logic [3:0] dbg_t_bst;
    logic [2:0] dbg_t_dst, dbg_t_rg;
    logic dbg_t_miss, dbg_t_dirty, dbg_t_req;

    logic dma_go, dma_wr, dma_busy, dma_done;
    logic dma_w_valid, dma_w_ready, dma_r_valid, dma_r_ready;
    logic [27:0] dma_addr;
    logic [31:0] dma_bytes;
    logic [127:0] dma_w_data, dma_r_data;

    assign dma_go      = t_owner ? t_go      : (p_owner ? p_go      : 1'b0);
    assign dma_wr      = t_owner ? t_wr      : p_wr;
    assign dma_addr    = t_owner ? t_dma_addr : p_dma_addr;
    assign dma_bytes   = t_owner ? t_dma_bytes : p_dma_bytes;
    assign dma_w_valid = t_owner ? t_w_valid : p_w_valid;
    assign dma_w_data  = t_owner ? t_w_data  : p_w_data;
    assign dma_r_ready = t_owner ? t_r_ready : p_r_ready;
    assign t_w_ready   = dma_w_ready && t_owner;
    assign p_w_ready   = dma_w_ready && p_owner && !t_owner;
    assign t_r_valid   = dma_r_valid && t_owner;
    assign p_r_valid   = dma_r_valid && p_owner && !t_owner;
    assign t_r_data    = dma_r_data;
    assign p_r_data    = dma_r_data;

    logic host_we;
    logic [19:0] host_addr;
    logic signed [7:0] host_wd;
    assign t_we    = p_busy ? p_we    : host_we;
    assign t_addr  = p_busy ? p_addr  : host_addr;
    assign t_wdata = p_busy ? p_wdata : host_wd;
    assign p_rdata = t_rdata;
    assign p_stall = t_stall;

    weight_tile803k #(.SIM_FULL(1'b0)) u_tile (
        .clk(clk50), .rst_n(rst50_n), .clk_dma(clk_ui), .rst_dma_n(rst_ui_n),
        .we_a(t_we), .addr_a(t_addr), .wdata_a(t_wdata), .rdata_a(t_rdata),
        .addr_b(t_addr), .rdata_b(t_rdb),
        .stall(t_stall), .cached_rg(), .dirty(),
        .dma_owner(t_owner), .dma_go(t_go), .dma_wr(t_wr),
        .dma_addr(t_dma_addr), .dma_bytes(t_dma_bytes),
        .dma_busy(dma_busy), .dma_done(dma_done),
        .dma_w_valid(t_w_valid), .dma_w_ready(t_w_ready), .dma_w_data(t_w_data),
        .dma_r_valid(t_r_valid), .dma_r_ready(t_r_ready), .dma_r_data(t_r_data),
        .dbg_bst(dbg_t_bst), .dbg_dst(dbg_t_dst), .dbg_cur_rg(dbg_t_rg),
        .dbg_miss(dbg_t_miss), .dbg_dirty(dbg_t_dirty), .dbg_req(dbg_t_req)
    );

    lm06_persist u_p (
        .clk_bram(clk50), .rst_bram_n(rst50_n),
        .clk_dma(clk_ui), .rst_dma_n(rst_ui_n),
        .go_flush(go_flush), .go_reload(go_reload),
        .busy(p_busy), .done(p_done), .bytes_done(p_bytes),
        .last_under(), .last_berr(), .last_rerr(),
        .dma_owner(p_owner),
        .mem_sel(p_mem_sel),
        .mem_we(p_we), .mem_addr(p_addr), .mem_wdata(p_wdata), .mem_rdata(p_rdata),
        .mem_stall(p_stall),
        .dma_go(p_go), .dma_wr(p_wr), .dma_addr(p_dma_addr), .dma_bytes(p_dma_bytes),
        .dma_busy(dma_busy), .dma_done(dma_done), .tile_hold(t_owner),
        .dma_under(1'b0), .axi_berr(1'b0), .axi_rerr(1'b0),
        .dma_w_valid(p_w_valid), .dma_w_ready(p_w_ready), .dma_w_data(p_w_data),
        .dma_r_valid(p_r_valid), .dma_r_ready(p_r_ready), .dma_r_data(p_r_data),
        .dbg_bst(dbg_p_bst), .dbg_dst(dbg_p_dst), .dbg_ch(dbg_p_ch),
        .dbg_is_flush(dbg_p_flush), .dbg_req(dbg_p_req)
    );

    // Mock MIG: ignore go while busy (the C1 lost-go case).
    logic [3:0] beat;
    logic [1:0] dly;
    logic [31:0] ignored_go;
    typedef enum logic [1:0] {M_IDLE, M_DLY, M_XFER, M_DONE} mst_t;
    mst_t mst;
    assign dma_busy = ((mst != M_IDLE) && (mst != M_DONE))
                   || (dma_go && (mst == M_IDLE));
    assign dma_r_data = {4{32'(dma_addr)}};
    always_ff @(posedge clk_ui) begin
        if (!rst_ui_n) begin
            mst <= M_IDLE;
            beat <= 0;
            dly <= 0;
            ignored_go <= 0;
            dma_done <= 0;
            dma_r_valid <= 0;
            dma_w_ready <= 0;
        end else begin
            dma_done <= 0;
            dma_r_valid <= 0;
            dma_w_ready <= 0;
            if (dma_go && (mst != M_IDLE))
                ignored_go <= ignored_go + 1;
            unique case (mst)
                M_IDLE: if (dma_go) begin
                    dly <= 2'd2;
                    beat <= 0;
                    mst <= M_DLY;
                end
                M_DLY: if (dly == 0) mst <= M_XFER;
                       else dly <= dly - 2'd1;
                M_XFER: begin
                    if (dma_wr) begin
                        dma_w_ready <= 1'b1;
                        if (dma_w_valid) begin
                            if (beat == 4'd7) mst <= M_DONE;
                            else beat <= beat + 4'd1;
                        end
                    end else begin
                        dma_r_valid <= 1'b1;
                        if (dma_r_ready) begin
                            if (beat == 4'd7) mst <= M_DONE;
                            else beat <= beat + 4'd1;
                        end
                    end
                end
                M_DONE: begin
                    dma_done <= 1'b1;
                    mst <= M_IDLE;
                end
                default: mst <= M_IDLE;
            endcase
        end
    end

    task automatic dump(input string tag);
        $display("%s pbst=%0d pdst=%0d pch=%0d preq=%0d pown=%0d psel=%0d tbst=%0d tdst=%0d trg=%0d town=%0d stall=%0d busy=%0d pgo=%0d tgo=%0d mgo=%0d ign=%0d bytes=%0d",
                 tag, dbg_p_bst, dbg_p_dst, dbg_p_ch, dbg_p_req, p_owner, p_mem_sel,
                 dbg_t_bst, dbg_t_dst, dbg_t_rg, t_owner, t_stall, dma_busy,
                 p_go, t_go, dma_go, ignored_go, p_bytes);
    endtask

    task automatic wait_stall_clear(input int lim);
        int n;
        n = 0;
        while (t_stall && n < lim) begin
            @(posedge clk50);
            n++;
        end
        if (t_stall) begin
            dump("TB_FAIL stall timeout");
            $finish;
        end
    endtask

    initial begin
        host_we = 0;
        host_addr = 0;
        host_wd = 0;
        repeat (8) @(posedge clk50);
        rst50_n = 1;
        rst_ui_n = 1;
        repeat (16) @(posedge clk50);

        // Park tile on HEAD so reload addr 0 is a TOK miss (C1 hang shape).
        host_addr = 20'(OFF_HEAD);
        repeat (4) @(posedge clk50);
        if (!t_stall) begin
            dump("TB_FAIL park no stall");
            $finish;
        end
        wait_stall_clear(2_000_000);
        if (dbg_t_rg != 3'd6) begin
            $display("TB_FAIL park rg=%0d want HEAD=6", dbg_t_rg);
            dump("park");
            $finish;
        end
        $display("parked HEAD rg=%0d", dbg_t_rg);

        @(posedge clk50);
        go_reload = 1;
        @(posedge clk50);
        go_reload = 0;
        dump("reload_start");

        begin
            int n;
            int saw_miss;
            n = 0;
            saw_miss = 0;
            while (!p_done && n < 5_000_000) begin
                @(posedge clk50);
                n++;
                if (t_stall && (dbg_t_rg == 3'd6) && p_mem_sel)
                    saw_miss = 1;
                if (n % 200000 == 0)
                    dump($sformatf("reload n=%0d", n));
                // C2 unit gate: first two persist chunks after a HEAD->TOK miss.
                if (saw_miss && (p_bytes >= 32'd256)) begin
                    $display("A7LM06_PERSIST_RELOAD_PASS bytes=%0d ign=%0d n=%0d miss=1",
                             p_bytes, ignored_go, n);
                    $finish;
                end
            end
            dump("TB_FAIL persist hang");
            $display("TB_FAIL persist hang done=%0d bytes=%0d ign=%0d pbst=%0d tbst=%0d saw_miss=%0d",
                     p_done, p_bytes, ignored_go, dbg_p_bst, dbg_t_bst, saw_miss);
            $finish;
        end
    end
endmodule
