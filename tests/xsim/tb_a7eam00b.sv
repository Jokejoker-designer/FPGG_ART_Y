`timescale 1ns/1ps
module tb_a7eam00b;
    localparam int CLKS = (100_000_000 + 115200/2) / 115200;
    logic clk = 0, rst_n = 0, rx = 1, tx;
    logic last_hit, idle;
    always #5 clk = ~clk;

    logic [7:0] rxq [$];
    bit rx_busy;
    always @(negedge tx) begin
        logic [7:0] b;
        int i;
        if (rst_n && !rx_busy) begin
            rx_busy = 1'b1;
            repeat (CLKS / 2) @(posedge clk);
            b = 8'd0;
            for (i = 0; i < 8; i++) begin
                repeat (CLKS) @(posedge clk);
                b[i] = tx;
            end
            repeat (CLKS) @(posedge clk);
            rxq.push_back(b);
            rx_busy = 1'b0;
        end
    end

    eam00b_uart u_dut (
        .clk(clk), .rst_n(rst_n), .rx(rx), .tx(tx),
        .last_hit(last_hit), .core_idle(idle)
    );

    task automatic uart_send_byte(input [7:0] b);
        int i;
        begin
            rx = 1'b0;
            repeat (CLKS) @(posedge clk);
            for (i = 0; i < 8; i++) begin
                rx = b[i];
                repeat (CLKS) @(posedge clk);
            end
            rx = 1'b1;
            repeat (CLKS) @(posedge clk);
        end
    endtask

    task automatic uart_get_byte(output [7:0] b);
        int guard;
        begin
            guard = 0;
            while (rxq.size() == 0) begin
                @(posedge clk);
                guard++;
                if (guard > 400000) begin
                    $display("TB_FAIL rxq timeout st=%0d n=%0d", u_dut.st, rxq.size());
                    $finish;
                end
            end
            b = rxq.pop_front();
        end
    endtask

    task automatic send_cmd(input [7:0] cmd);
        logic [7:0] x;
        begin
            x = 8'hA5 ^ cmd ^ 8'd0;
            uart_send_byte(8'hA5);
            uart_send_byte(cmd);
            uart_send_byte(8'd0);
            uart_send_byte(x);
        end
    endtask

    task automatic send_qv(input [7:0] cmd, input [63:0] k, input [127:0] v, input [7:0] t);
        logic [7:0] pay [0:24];
        logic [7:0] x;
        int i;
        begin
            for (i = 0; i < 8; i++)
                pay[i] = k[8*i +: 8];
            for (i = 0; i < 16; i++)
                pay[8+i] = v[8*i +: 8];
            pay[24] = t;
            x = 8'hA5 ^ cmd ^ 8'd25;
            for (i = 0; i < 25; i++)
                x = x ^ pay[i];
            uart_send_byte(8'hA5);
            uart_send_byte(cmd);
            uart_send_byte(8'd25);
            for (i = 0; i < 25; i++)
                uart_send_byte(pay[i]);
            uart_send_byte(x);
        end
    endtask

    task automatic recv_reply(output logic [7:0] r [0:19]);
        int i;
        logic [7:0] x;
        begin
            for (i = 0; i < 20; i++)
                uart_get_byte(r[i]);
            if (r[0] !== 8'h5A) begin
                $display("TB_FAIL bad sync %02h", r[0]);
                $finish;
            end
            x = 8'd0;
            for (i = 0; i < 19; i++)
                x = x ^ r[i];
            if (x !== r[19]) begin
                $display("TB_FAIL reply xor got=%02h exp=%02h", r[19], x);
                $finish;
            end
        end
    endtask

    logic [7:0] reply [0:19];
    integer i;
    logic [63:0] keys [0:3];
    logic [7:0]  toks [0:3];

    initial begin
        repeat (20) @(posedge clk);
        rst_n = 1;
        repeat (40) @(posedge clk);

        $display("TB ping send");
        send_cmd(8'h01);
        $display("TB ping wait st=%0d", u_dut.st);
        recv_reply(reply);
        $display("TB ping kind=%02h", reply[1]);
        if (reply[1] !== 8'h81 || reply[3] !== 8'h45) begin
            $display("TB_FAIL ping kind=%02h", reply[1]);
            $finish;
        end

        send_cmd(8'h05);
        recv_reply(reply);

        for (i = 0; i < 4; i++) begin
            keys[i] = 64'h1111111100000000 + (64'(i) << 8) + 64'(i);
            toks[i] = 8'(8'h30 + i);
            send_qv(8'h02, keys[i], 128'(i+1), toks[i]);
            recv_reply(reply);
            if (reply[1] !== 8'h82 || reply[2][0]) begin
                $display("TB_FAIL first miss i=%0d kind=%02h flags=%02h",
                         i, reply[1], reply[2]);
                $finish;
            end
        end

        for (i = 0; i < 4; i++) begin
            send_qv(8'h03, keys[i], 128'd0, 8'd0);
            recv_reply(reply);
            if (reply[1] !== 8'h82 || !reply[2][0] ||
                reply[3] !== toks[i] || reply[4] !== 8'd0) begin
                $display("TB_FAIL probe i=%0d hit=%0d tok=%0d d=%0d",
                         i, reply[2][0], reply[3], reply[4]);
                $finish;
            end
        end

        send_cmd(8'h04);
        recv_reply(reply);
        send_qv(8'h03, keys[0], 128'd0, 8'd0);
        recv_reply(reply);
        if (reply[2][0]) begin
            $display("TB_FAIL epoch still hits");
            $finish;
        end

        $display("A7EAM00B_XSIM_PASS");
        $finish;
    end
endmodule
