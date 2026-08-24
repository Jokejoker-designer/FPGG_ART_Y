`timescale 1ns/1ps
import a7eam00_pkg::*;
module tb_a7eam00;
    logic clk = 0, rst_n = 0;
    always #5 clk = ~clk;

    logic [63:0]  query_key;
    logic         query_start;
    logic [127:0] context_vec;
    logic [7:0]   context_token;
    logic         idle, busy, result_valid, hit;
    logic [7:0]   out_token, out_confidence, ctrl_token;
    logic [127:0] out_vector;
    logic [3:0]   out_way;
    logic [6:0]   out_hamming;
    logic [255:0] ctrl_state;
    logic signed [15:0] ctrl_energy;

    logic [7:0]  awaddr, araddr;
    logic        awvalid, awready, wvalid, wready, bvalid, bready;
    logic        arvalid, arready, rvalid, rready;
    logic [31:0] wdata, rdata;
    logic [3:0]  wstrb;
    logic [1:0]  bresp, rresp;

    a7eam00_top u_dut (
        .clk(clk), .rst_n(rst_n),
        .query_key(query_key), .query_start(query_start),
        .context_vec(context_vec), .context_token(context_token),
        .idle(idle), .busy(busy), .result_valid(result_valid), .hit(hit),
        .out_token(out_token), .out_vector(out_vector),
        .out_confidence(out_confidence), .out_way(out_way),
        .out_hamming(out_hamming),
        .ctrl_state(ctrl_state), .ctrl_energy(ctrl_energy), .ctrl_token(ctrl_token),
        .s_axil_awaddr(awaddr), .s_axil_awvalid(awvalid), .s_axil_awready(awready),
        .s_axil_wdata(wdata), .s_axil_wstrb(wstrb), .s_axil_wvalid(wvalid),
        .s_axil_wready(wready), .s_axil_bresp(bresp), .s_axil_bvalid(bvalid),
        .s_axil_bready(bready),
        .s_axil_araddr(araddr), .s_axil_arvalid(arvalid), .s_axil_arready(arready),
        .s_axil_rdata(rdata), .s_axil_rresp(rresp), .s_axil_rvalid(rvalid),
        .s_axil_rready(rready)
    );

    localparam int NMAP = 48;

    logic [63:0]  keys [0:NMAP-1];
    logic [7:0]   toks [0:NMAP-1];
    logic [127:0] vecs [0:NMAP-1];

    task automatic axil_wr(input [7:0] a, input [31:0] d);
        begin
            awaddr = a; wdata = d; wstrb = 4'hF;
            awvalid = 1; wvalid = 1; bready = 1;
            while (!(awready && wready)) @(posedge clk);
            @(posedge clk);
            awvalid = 0; wvalid = 0;
            while (!bvalid) @(posedge clk);
            @(posedge clk);
            bready = 0;
        end
    endtask

    task automatic axil_rd(input [7:0] a, output [31:0] d);
        begin
            araddr = a; arvalid = 1; rready = 1;
            while (!arready) @(posedge clk);
            @(posedge clk);
            arvalid = 0;
            while (!rvalid) @(posedge clk);
            d = rdata;
            @(posedge clk);
            rready = 0;
        end
    endtask

    task automatic do_query(
        input [63:0] k,
        input [127:0] v,
        input [7:0] t
    );
        int guard;
        begin
            while (!idle) @(posedge clk);
            query_key = k;
            context_vec = v;
            context_token = t;
            query_start = 1;
            @(posedge clk);
            query_start = 0;
            guard = 0;
            while (!result_valid) begin
                @(posedge clk);
                guard++;
                if (guard > 160) begin
                    $display("TB_FAIL query timeout key=%h", k);
                    $finish;
                end
            end
        end
    endtask

    integer i, j;
    logic [31:0] rd;
    int nmiss, nhit, nbad;

    initial begin
        query_key = 0;
        query_start = 0;
        context_vec = 0;
        context_token = 0;
        awaddr = 0; awvalid = 0; wvalid = 0; wdata = 0; wstrb = 0; bready = 0;
        araddr = 0; arvalid = 0; rready = 0;
        repeat (20) @(posedge clk);
        rst_n = 1;
        repeat (40) @(posedge clk);

        for (i = 0; i < NMAP; i++) begin
            keys[i] = {$urandom, $urandom};
            keys[i][7:0] = 8'(i < 16 ? 8'hA5 : 8'(i));
            toks[i] = 8'(8'h10 + i);
            vecs[i] = {32'($urandom), 32'($urandom), 32'($urandom), 32'($urandom)};
        end

        nmiss = 0;
        for (i = 0; i < NMAP; i++) begin
            do_query(keys[i], vecs[i], toks[i]);
            if (hit) begin
                $display("TB_FAIL first query hit i=%0d", i);
                $finish;
            end
            if (out_token !== toks[i]) begin
                $display("TB_FAIL miss token i=%0d got=%0d", i, out_token);
                $finish;
            end
            nmiss++;
            @(posedge clk);
        end

        nhit = 0;
        nbad = 0;
        for (i = 0; i < NMAP; i++) begin
            do_query(keys[i], vecs[i], toks[i]);
            if (!hit || out_token !== toks[i] || out_hamming !== 7'd0) begin
                $display("TB_FAIL recall i=%0d hit=%0d tok=%0d d=%0d",
                         i, hit, out_token, out_hamming);
                nbad++;
            end else
                nhit++;
            @(posedge clk);
        end
        if (nbad != 0) begin
            $display("TB_FAIL recall nbad=%0d", nbad);
            $finish;
        end

        begin
            logic [63:0] ek;
            logic [7:0]  et;
            logic [127:0] ev;
            ek = {56'hBEEFBEEFBEEBEE, 8'hA5};
            et = 8'hFE;
            ev = 128'h1111;
            do_query(ek, ev, et);
            if (hit) begin
                $display("TB_FAIL 17th same-set should miss/evict");
                $finish;
            end
            @(posedge clk);
            do_query(ek, ev, et);
            if (!hit || out_token !== et) begin
                $display("TB_FAIL evict recall tok=%0d hit=%0d", out_token, hit);
                $finish;
            end
            @(posedge clk);
        end

        axil_rd(8'h08, rd);
        if (rd < 32'(NMAP)) begin
            $display("TB_FAIL HIT_CNT=%0d", rd);
            $finish;
        end
        axil_rd(8'h0C, rd);
        if (rd < 32'(NMAP + 1)) begin
            $display("TB_FAIL MISS_CNT=%0d", rd);
            $finish;
        end
        axil_wr(8'h00, 32'd1);
        repeat (4) @(posedge clk);
        do_query(keys[20], vecs[20], toks[20]);
        if (hit) begin
            $display("TB_FAIL epoch reset still hit");
            $finish;
        end

        $display("A7EAM00_XSIM_PASS maps=%0d hits=%0d first_miss=%0d energy=%0d cyc_ok",
                 NMAP, nhit, nmiss, ctrl_energy);
        $finish;
    end
endmodule
