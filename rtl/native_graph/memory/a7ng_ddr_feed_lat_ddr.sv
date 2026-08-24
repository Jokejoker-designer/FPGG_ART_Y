// a7ng_ddr_feed_lat_ddr.sv — synthetic DDR with fixed latency + burst + multi-outstanding
// WM-01 / ddr_feed. NOT MIG silicon (H_RIVAL remains OPEN). FPGA owns addresses (HS-14).
// Law: a7ng-ddr-feed-wm01-v0.
`timescale 1ns / 1ps

module a7ng_ddr_feed_lat_ddr #(
  parameter int unsigned N_NODES   = 1024,
  parameter int unsigned LATENCY   = 24,
  parameter int unsigned MAX_OUT   = 8,
  parameter int unsigned MAX_BURST = 16
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        ar_valid_i,
  output logic        ar_ready_o,
  input  logic [31:0] ar_addr_i,
  input  logic [7:0]  ar_len_i,
  input  logic [3:0]  ar_id_i,
  output logic        r_valid_o,
  input  logic        r_ready_i,
  output logic [127:0] r_data_o,
  output logic        r_last_o,
  output logic [3:0]  r_id_o,
  output logic [31:0] ddr_rd_bytes_o,
  output logic [31:0] ddr_rd_count_o,
  output logic [31:0] ddr_burst_count_o,
  output logic [7:0]  outstanding_o
);
  import a7ng_mem_schema_v1_pkg::*;

  (* ram_style = "distributed" *) logic [127:0] node_mem [N_NODES];

  function automatic logic [127:0] pack_node(input logic [31:0] nid);
    logic [127:0] b;
    b = '0;
    b[31:0]    = nid;
    b[47:32]   = 16'd1;
    b[63:48]   = 16'(nid[7:0]);
    b[95:64]   = 32'hDDFE_0000 + nid;
    b[111:96]  = 16'h0100;
    b[119:112] = 8'(nid[7:0]);
    b[127:120] = A7NG_MEM_SCHEMA_VERSION[7:0];
    return b;
  endfunction

  integer ii;
  initial begin
    for (ii = 0; ii < N_NODES; ii = ii + 1)
      node_mem[ii] = pack_node(32'(ii));
  end

  typedef struct packed {
    logic        v;
    logic [31:0] base;
    logic [7:0]  rem;       // remaining beats
    logic [7:0]  total;
    logic [15:0] wait_c;
    logic [3:0]  id;
  } slot_t;

  slot_t slot [MAX_OUT];
  logic [$clog2(MAX_OUT+1)-1:0] n_out;
  logic [31:0] rd_b, rd_c, br_c;

  assign ddr_rd_bytes_o    = rd_b;
  assign ddr_rd_count_o    = rd_c;
  assign ddr_burst_count_o = br_c;
  assign outstanding_o     = 8'(n_out);
  assign ar_ready_o        = (n_out < MAX_OUT[$clog2(MAX_OUT+1)-1:0]);

  logic       pick_v;
  logic [3:0] pick_i;
  always_comb begin
    pick_v = 1'b0;
    pick_i = 4'd0;
    for (int s = 0; s < MAX_OUT; s++) begin
      if (!pick_v && slot[s].v && (slot[s].wait_c == 16'd0)) begin
        pick_v = 1'b1;
        pick_i = 4'(s);
      end
    end
  end

  logic [31:0] cur_nid;
  assign cur_nid   = slot[pick_i].base + 32'(slot[pick_i].total - slot[pick_i].rem);
  assign r_valid_o = pick_v;
  assign r_data_o  = pick_v ? node_mem[cur_nid[$clog2(N_NODES)-1:0]] : '0;
  assign r_last_o  = pick_v && (slot[pick_i].rem == 8'd1);
  assign r_id_o    = pick_v ? slot[pick_i].id : 4'd0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      n_out <= '0;
      rd_b  <= 32'd0;
      rd_c  <= 32'd0;
      br_c  <= 32'd0;
      for (int s = 0; s < MAX_OUT; s++)
        slot[s] <= '0;
    end else begin
      logic [$clog2(MAX_OUT+1)-1:0] n_next;
      logic                         took_ar;

      n_next = n_out;
      took_ar = 1'b0;

      for (int s = 0; s < MAX_OUT; s++) begin
        if (slot[s].v && slot[s].wait_c != 16'd0)
          slot[s].wait_c <= slot[s].wait_c - 16'd1;
      end

      if (ar_valid_i && ar_ready_o) begin
        for (int s = 0; s < MAX_OUT; s++) begin
          if (!took_ar && !slot[s].v) begin
            slot[s].v      <= 1'b1;
            slot[s].base   <= ar_addr_i;
            slot[s].rem    <= ar_len_i + 8'd1;
            slot[s].total  <= ar_len_i + 8'd1;
            slot[s].wait_c <= 16'(LATENCY);
            slot[s].id     <= ar_id_i;
            took_ar = 1'b1;
            n_next = n_next + 1'b1;
            br_c   <= br_c + 32'd1;
          end
        end
      end

      if (r_valid_o && r_ready_i) begin
        rd_b <= rd_b + A7NG_NODE_REC_BYTES;
        rd_c <= rd_c + 32'd1;
        if (slot[pick_i].rem == 8'd1) begin
          slot[pick_i].v <= 1'b0;
          n_next = n_next - 1'b1;
        end else begin
          slot[pick_i].rem <= slot[pick_i].rem - 8'd1;
        end
      end

      n_out <= n_next;
    end
  end
endmodule
