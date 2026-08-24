`timescale 1ns/1ps
import a7eam00_pkg::*;
module a7eam00_top (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [63:0]  query_key,
    input  logic         query_start,
    input  logic [127:0] context_vec,
    input  logic [7:0]   context_token,
    output logic         idle,
    output logic         busy,
    output logic         result_valid,
    output logic         hit,
    output logic [7:0]   out_token,
    output logic [127:0] out_vector,
    output logic [7:0]   out_confidence,
    output logic [3:0]   out_way,
    output logic [6:0]   out_hamming,
    output logic [255:0] ctrl_state,
    output logic signed [15:0] ctrl_energy,
    output logic [7:0]   ctrl_token,
    input  logic [7:0]   s_axil_awaddr,
    input  logic         s_axil_awvalid,
    output logic         s_axil_awready,
    input  logic [31:0]  s_axil_wdata,
    input  logic [3:0]   s_axil_wstrb,
    input  logic         s_axil_wvalid,
    output logic         s_axil_wready,
    output logic [1:0]   s_axil_bresp,
    output logic         s_axil_bvalid,
    input  logic         s_axil_bready,
    input  logic [7:0]   s_axil_araddr,
    input  logic         s_axil_arvalid,
    output logic         s_axil_arready,
    output logic [31:0]  s_axil_rdata,
    output logic [1:0]   s_axil_rresp,
    output logic         s_axil_rvalid,
    input  logic         s_axil_rready
);
    logic        axi_start, soft_rst, clr_stat, auto_update;
    logic        dbg_fetch, dbg_commit, dbg_ack;
    logic [63:0] axi_key;
    logic [127:0] axi_ctx;
    logic [7:0]  axi_tok, hit_max, epoch, last_cycles;
    logic [3:0]  ema_shift;
    logic [EAM_AW-1:0] dbg_index;
    logic [255:0] dbg_wdata, dbg_rdata;
    logic [31:0] hit_cnt, miss_cnt, qry_cnt;

    logic        qstart_n, qstart;
    logic [63:0] qkey_n, qkey;
    logic [127:0] qctx_n, qctx;
    logic [7:0]  qtok_n, qtok;
    logic        idle_i, rvalid_i, hit_i;
    logic [7:0]  otok_i, oconf_i, ctok_i;
    logic [127:0] ovec_i;
    logic [3:0]  oway_i;
    logic [6:0]  oham_i;
    logic [255:0] cstate_i;
    logic signed [15:0] cenergy_i;

    // AXI inputs registered at the OOC boundary (2 ns I/O delay @ 100 MHz).
    logic [7:0]  awaddr_q, araddr_q;
    logic        awvalid_q, wvalid_q, arvalid_q, bready_q, rready_q;
    logic [31:0] wdata_q;
    logic [3:0]  wstrb_q;
    logic        awready_i, wready_i, arready_i, bvalid_i, rvalid_ax;
    logic [1:0]  bresp_i, rresp_i;
    logic [31:0] rdata_i;

    assign qstart_n = query_start || axi_start;
    assign qkey_n   = axi_start ? axi_key : query_key;
    assign qctx_n   = axi_start ? axi_ctx : context_vec;
    assign qtok_n   = axi_start ? axi_tok : context_token;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            qstart <= 1'b0;
            qkey   <= '0;
            qctx   <= '0;
            qtok   <= '0;
            idle          <= 1'b0;
            busy          <= 1'b1;
            result_valid  <= 1'b0;
            hit           <= 1'b0;
            out_token     <= '0;
            out_vector    <= '0;
            out_confidence<= '0;
            out_way       <= '0;
            out_hamming   <= 7'd64;
            ctrl_state    <= '0;
            ctrl_energy   <= '0;
            ctrl_token    <= '0;
            awaddr_q  <= '0;
            araddr_q  <= '0;
            awvalid_q <= 1'b0;
            wvalid_q  <= 1'b0;
            arvalid_q <= 1'b0;
            bready_q  <= 1'b0;
            rready_q  <= 1'b0;
            wdata_q   <= '0;
            wstrb_q   <= '0;
            s_axil_awready <= 1'b0;
            s_axil_wready  <= 1'b0;
            s_axil_arready <= 1'b0;
            s_axil_bresp   <= 2'b00;
            s_axil_bvalid  <= 1'b0;
            s_axil_rdata   <= '0;
            s_axil_rresp   <= 2'b00;
            s_axil_rvalid  <= 1'b0;
        end else begin
            awaddr_q  <= s_axil_awaddr;
            araddr_q  <= s_axil_araddr;
            awvalid_q <= s_axil_awvalid;
            wvalid_q  <= s_axil_wvalid;
            arvalid_q <= s_axil_arvalid;
            bready_q  <= s_axil_bready;
            rready_q  <= s_axil_rready;
            wdata_q   <= s_axil_wdata;
            wstrb_q   <= s_axil_wstrb;
            s_axil_awready <= awready_i;
            s_axil_wready  <= wready_i;
            s_axil_arready <= arready_i;
            s_axil_bresp   <= bresp_i;
            s_axil_bvalid  <= bvalid_i;
            s_axil_rdata   <= rdata_i;
            s_axil_rresp   <= rresp_i;
            s_axil_rvalid  <= rvalid_ax;
            qstart <= qstart_n;
            qkey   <= qkey_n;
            qctx   <= qctx_n;
            qtok   <= qtok_n;
            idle          <= idle_i;
            busy          <= !idle_i;
            result_valid  <= rvalid_i;
            hit           <= hit_i;
            out_token     <= otok_i;
            out_vector    <= ovec_i;
            out_confidence<= oconf_i;
            out_way       <= oway_i;
            out_hamming   <= oham_i;
            ctrl_state    <= cstate_i;
            ctrl_energy   <= cenergy_i;
            ctrl_token    <= ctok_i;
        end
    end

    eam_core u_core (
        .clk(clk), .rst_n(rst_n),
        .query_start(qstart), .query_key(qkey),
        .context_vec(qctx), .context_token(qtok),
        .hit_max(hit_max), .ema_shift(ema_shift), .auto_update(auto_update),
        .soft_rst(soft_rst), .clr_stat(clr_stat),
        .idle(idle_i), .result_valid(rvalid_i), .hit(hit_i),
        .out_token(otok_i), .out_vector(ovec_i),
        .out_confidence(oconf_i), .out_way(oway_i),
        .out_hamming(oham_i),
        .out_second(),
        .hit_cnt(hit_cnt), .miss_cnt(miss_cnt), .qry_cnt(qry_cnt),
        .epoch(epoch), .last_cycles(last_cycles),
        .dbg_fetch(dbg_fetch), .dbg_commit(dbg_commit),
        .dbg_index(dbg_index), .dbg_wdata(dbg_wdata),
        .dbg_rdata(dbg_rdata), .dbg_ack(dbg_ack)
    );

    eam_controller u_ctrl (
        .clk(clk), .rst_n(rst_n),
        .go(rvalid_i), .hit(hit_i),
        .vec(ovec_i), .token(otok_i),
        .state_bits(cstate_i), .energy(cenergy_i), .token_hat(ctok_i)
    );

    eam_axil u_axil (
        .clk(clk), .rst_n(rst_n),
        .s_axil_awaddr(awaddr_q), .s_axil_awvalid(awvalid_q),
        .s_axil_awready(awready_i),
        .s_axil_wdata(wdata_q), .s_axil_wstrb(wstrb_q),
        .s_axil_wvalid(wvalid_q), .s_axil_wready(wready_i),
        .s_axil_bresp(bresp_i), .s_axil_bvalid(bvalid_i),
        .s_axil_bready(bready_q),
        .s_axil_araddr(araddr_q), .s_axil_arvalid(arvalid_q),
        .s_axil_arready(arready_i),
        .s_axil_rdata(rdata_i), .s_axil_rresp(rresp_i),
        .s_axil_rvalid(rvalid_ax), .s_axil_rready(rready_q),
        .core_idle(idle_i), .last_hit(hit_i), .last_dist(oham_i),
        .last_way(oway_i),
        .hit_cnt(hit_cnt), .miss_cnt(miss_cnt), .qry_cnt(qry_cnt),
        .last_cycles(last_cycles), .epoch(epoch),
        .dbg_ack(dbg_ack), .dbg_rdata(dbg_rdata),
        .soft_rst(soft_rst), .clr_stat(clr_stat),
        .axi_start(axi_start), .axi_key(axi_key), .axi_ctx(axi_ctx),
        .axi_tok(axi_tok), .hit_max(hit_max), .ema_shift(ema_shift),
        .auto_update(auto_update),
        .dbg_fetch(dbg_fetch), .dbg_commit(dbg_commit),
        .dbg_index(dbg_index), .dbg_wdata(dbg_wdata)
    );
endmodule
