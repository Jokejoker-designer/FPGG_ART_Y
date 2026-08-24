`timescale 1ns/1ps
import a7eam00_pkg::*;
// UART transport only. FPGA owns set/scan/popcount/winner/hit/alloc/evict/EMA.
// Reply never contains way or BRAM address.
module eam00b_uart (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         rx,
    output logic         tx,
    output logic         last_hit,
    output logic         core_idle
);
    localparam int CLK_HZ = 100_000_000;
    localparam int BAUD   = 115200;
    localparam int MAXP   = 32;
    localparam int RLEN   = 20;

    localparam logic [7:0] CMD_PING  = 8'h01;
    localparam logic [7:0] CMD_MAP   = 8'h02;
    localparam logic [7:0] CMD_PROBE = 8'h03;
    localparam logic [7:0] CMD_SOFT  = 8'h04;
    localparam logic [7:0] CMD_CLR   = 8'h05;
    localparam logic [7:0] CMD_STAT  = 8'h06;
    localparam logic [7:0] CMD_HMAX  = 8'h07;
    localparam logic [7:0] K_PONG    = 8'h81;
    localparam logic [7:0] K_RES     = 8'h82;
    localparam logic [7:0] K_ACK     = 8'h83;
    localparam logic [7:0] K_ERR     = 8'h8E;

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       tx_start, tx_busy;
    logic [7:0] tx_data;
    logic       tx_i;

    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_rx (
        .clk(clk), .rst_n(rst_n), .rx(rx), .data(rx_data), .valid(rx_valid)
    );
    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_tx (
        .clk(clk), .rst_n(rst_n), .start(tx_start), .data(tx_data),
        .tx(tx_i), .busy(tx_busy)
    );
    assign tx = tx_i;

    logic        qstart, auto_upd, soft_rst, clr_stat;
    logic [63:0] qkey;
    logic [127:0] qvec;
    logic [7:0]  qtok;
    logic        idle, rvalid, hit;
    logic [7:0]  otok, oconf, epoch, last_cyc;
    logic [127:0] ovec;
    logic [3:0]  oway;
    logic [6:0]  oham, osec;
    logic [7:0]  hit_max_r;
    logic [31:0] hit_cnt, miss_cnt, qry_cnt;

    assign core_idle = idle;

    eam_core u_core (
        .clk(clk), .rst_n(rst_n),
        .query_start(qstart), .query_key(qkey),
        .context_vec(qvec), .context_token(qtok),
        .hit_max(hit_max_r), .ema_shift(4'd2), .auto_update(auto_upd),
        .soft_rst(soft_rst), .clr_stat(clr_stat),
        .idle(idle), .result_valid(rvalid), .hit(hit),
        .out_token(otok), .out_vector(ovec),
        .out_confidence(oconf), .out_way(oway),
        .out_hamming(oham), .out_second(osec),
        .hit_cnt(hit_cnt), .miss_cnt(miss_cnt), .qry_cnt(qry_cnt),
        .epoch(epoch), .last_cycles(last_cyc),
        .dbg_fetch(1'b0), .dbg_commit(1'b0),
        .dbg_index('0), .dbg_wdata('0),
        .dbg_rdata(), .dbg_ack()
    );

    typedef enum logic [3:0] {
        S_SYNC, S_CMD, S_LEN, S_PAY, S_XOR, S_GO, S_PACK, S_PRES, S_WAIT, S_TX
    } st_t;
    st_t st;

    logic [7:0] cmd, n, acc, got;
    logic [5:0] pi, ti;
    logic       tx_armed;
    logic [7:0] pay [0:MAXP-1];
    logic [7:0] rbuf [0:RLEN-1];
    logic       lat_hit;
    logic [7:0] lat_tok, lat_cyc;
    logic [6:0] lat_ham, lat_sec;

    assign last_hit = lat_hit;

    function automatic logic [7:0] rxor;
        int i;
        logic [7:0] x;
        begin
            x = 8'h00;
            for (i = 0; i < RLEN - 1; i++)
                x = x ^ rbuf[i];
            return x;
        end
    endfunction

    task automatic fill_reply(input logic [7:0] kind, input logic is_res);
        begin
            rbuf[0]  = 8'h5A;
            rbuf[1]  = kind;
            rbuf[2]  = {5'd0, idle, is_res, lat_hit};
            rbuf[3]  = is_res ? lat_tok : 8'd0;
            rbuf[4]  = is_res ? {1'b0, lat_ham} : 8'd0;
            rbuf[5]  = is_res ? {1'b0, lat_sec} : hit_max_r;
            rbuf[6]  = hit_cnt[7:0];
            rbuf[7]  = hit_cnt[15:8];
            rbuf[8]  = hit_cnt[23:16];
            rbuf[9]  = hit_cnt[31:24];
            rbuf[10] = miss_cnt[7:0];
            rbuf[11] = miss_cnt[15:8];
            rbuf[12] = miss_cnt[23:16];
            rbuf[13] = miss_cnt[31:24];
            rbuf[14] = qry_cnt[7:0];
            rbuf[15] = qry_cnt[15:8];
            rbuf[16] = qry_cnt[23:16];
            rbuf[17] = qry_cnt[31:24];
            rbuf[18] = epoch;
            rbuf[19] = rxor();
        end
    endtask

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= S_SYNC;
            cmd <= 8'd0;
            n <= 8'd0;
            acc <= 8'd0;
            got <= 8'd0;
            pi <= 6'd0;
            ti <= 6'd0;
            qstart <= 1'b0;
            auto_upd <= 1'b1;
            soft_rst <= 1'b0;
            clr_stat <= 1'b0;
            qkey <= '0;
            qvec <= '0;
            qtok <= 8'd0;
            tx_start <= 1'b0;
            tx_armed <= 1'b0;
            tx_data <= 8'd0;
            lat_hit <= 1'b0;
            lat_tok <= 8'd0;
            lat_ham <= 7'd0;
            lat_sec <= 7'd64;
            lat_cyc <= 8'd0;
            hit_max_r <= 8'd0;
        end else begin
            qstart   <= 1'b0;
            soft_rst <= 1'b0;
            clr_stat <= 1'b0;

            unique case (st)
                S_SYNC: if (rx_valid && rx_data == 8'hA5) begin
                    acc <= 8'hA5;
                    st <= S_CMD;
                end
                S_CMD: if (rx_valid) begin
                    cmd <= rx_data;
                    acc <= acc ^ rx_data;
                    st <= S_LEN;
                end
                S_LEN: if (rx_valid) begin
                    n <= rx_data;
                    acc <= acc ^ rx_data;
                    pi <= 6'd0;
                    if (rx_data == 8'd0)
                        st <= S_XOR;
                    else if (rx_data > MAXP[7:0])
                        st <= S_SYNC;
                    else
                        st <= S_PAY;
                end
                S_PAY: if (rx_valid) begin
                    pay[pi] <= rx_data;
                    acc <= acc ^ rx_data;
                    if (pi + 6'd1 == {2'b0, n[5:0]})
                        st <= S_XOR;
                    else
                        pi <= pi + 6'd1;
                end
                S_XOR: if (rx_valid) begin
                    got <= rx_data;
                    st <= S_GO;
                end
                S_GO: begin
                    if (got != acc) begin
                        fill_reply(K_ERR, 1'b0);
                        ti <= 6'd0;
                        st <= S_TX;
                    end else begin
                        unique case (cmd)
                            CMD_PING: begin
                                fill_reply(K_PONG, 1'b0);
                                rbuf[3] = 8'h45;
                                rbuf[4] = 8'h41;
                                rbuf[5] = 8'h4D;
                                rbuf[19] = rxor();
                                ti <= 6'd0;
                                st <= S_TX;
                            end
                            CMD_STAT: begin
                                fill_reply(K_ACK, 1'b0);
                                ti <= 6'd0;
                                st <= S_TX;
                            end
                            CMD_SOFT: begin
                                soft_rst <= 1'b1;
                                st <= S_PACK;
                            end
                            CMD_CLR: begin
                                clr_stat <= 1'b1;
                                st <= S_PACK;
                            end
                            CMD_HMAX: begin
                                if (n != 8'd1) begin
                                    fill_reply(K_ERR, 1'b0);
                                    ti <= 6'd0;
                                    st <= S_TX;
                                end else begin
                                    hit_max_r <= pay[0];
                                    st <= S_PACK;
                                end
                            end
                            CMD_MAP, CMD_PROBE: begin
                                if (n != 8'd25 || !idle) begin
                                    fill_reply(K_ERR, 1'b0);
                                    ti <= 6'd0;
                                    st <= S_TX;
                                end else begin
                                    qkey <= {pay[7], pay[6], pay[5], pay[4],
                                             pay[3], pay[2], pay[1], pay[0]};
                                    qvec <= {pay[23], pay[22], pay[21], pay[20],
                                             pay[19], pay[18], pay[17], pay[16],
                                             pay[15], pay[14], pay[13], pay[12],
                                             pay[11], pay[10], pay[9],  pay[8]};
                                    qtok <= pay[24];
                                    auto_upd <= (cmd == CMD_MAP);
                                    qstart <= 1'b1;
                                    st <= S_WAIT;
                                end
                            end
                            default: begin
                                fill_reply(K_ERR, 1'b0);
                                ti <= 6'd0;
                                st <= S_TX;
                            end
                        endcase
                    end
                end
                S_PACK: begin
                    fill_reply(K_ACK, 1'b0);
                    ti <= 6'd0;
                    st <= S_TX;
                end
                S_PRES: begin
                    fill_reply(K_RES, 1'b1);
                    ti <= 6'd0;
                    st <= S_TX;
                end
                S_WAIT: begin
                    if (rvalid) begin
                        lat_hit <= hit;
                        lat_tok <= otok;
                        lat_ham <= oham;
                        lat_sec <= osec;
                        lat_cyc <= last_cyc;
                        st <= S_PRES;
                    end
                end
                S_TX: begin
                    if (!tx_armed && !tx_busy) begin
                        tx_data  <= rbuf[ti];
                        tx_start <= 1'b1;
                        tx_armed <= 1'b1;
                    end else if (tx_armed && tx_busy) begin
                        tx_start <= 1'b0;
                        tx_armed <= 1'b0;
                        if (ti == 6'(RLEN - 1))
                            st <= S_SYNC;
                        else
                            ti <= ti + 6'd1;
                    end else
                        tx_start <= 1'b0;
                end
                default: st <= S_SYNC;
            endcase
        end
    end
endmodule
