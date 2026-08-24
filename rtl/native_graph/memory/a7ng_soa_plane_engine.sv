// a7ng_soa_plane_engine.sv — proven AR/R engine cloned from a7ng_cue_wavefront (ddr_wavefront_00 PASS)
// Gate: ddr_cue_soa_00r_axi_liveness attempt 7. Byte-addressed contiguous plane fetch only.
`timescale 1ns / 1ps

module a7ng_soa_plane_engine #(
  parameter int unsigned MAX_BEATS  = 52,
  parameter int unsigned MAX_OUT    = 8,
  parameter int unsigned MAX_BURST  = 16
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start_i,
  input  logic [4:0]   burst_i,
  input  logic [3:0]   outstanding_i,
  input  logic [27:0]  base_byte_i,
  input  logic [5:0]   beat_target_i,
  output logic         ar_valid_o,
  input  logic         ar_ready_i,
  output logic [27:0]  ar_addr_o,
  output logic [7:0]   ar_len_o,
  output logic [3:0]   ar_id_o,
  output logic [2:0]   ar_size_o,
  input  logic         r_valid_i,
  output logic         r_ready_o,
  input  logic [127:0] r_data_i,
  input  logic         r_last_i,
  output logic [127:0] beat_data_o [MAX_BEATS],
  output logic         running_o,
  output logic         done_o,
  output logic         done_pulse_o,
  output logic [5:0]   beats_returned_o,
  output logic [5:0]   beats_issued_o,
  output logic         idle_o,
  output logic [31:0]  ar_txns_o
);
  logic [5:0]       issued, returned, target;
  logic [31:0]      pending;
  logic [3:0]       in_flight, rid_q;
  logic             running;
  logic             done_pulse_q;
  logic [31:0]      ar_txns;

  logic        ar_valid_q;
  logic [27:0] ar_addr_q;
  logic [7:0]  ar_len_q;
  logic [3:0]  ar_id_q;
  logic [4:0]  this_burst_q;

  assign running_o        = running;
  assign idle_o           = !running && !ar_valid_q && (pending == 32'd0) && (in_flight == 4'd0);
  assign done_o           = !running && (returned >= target) && (target != 6'd0);
  assign done_pulse_o     = done_pulse_q;
  assign beats_returned_o = returned;
  assign beats_issued_o   = issued;
  assign ar_txns_o        = ar_txns;

  assign ar_valid_o = ar_valid_q;
  assign ar_addr_o  = ar_addr_q;
  assign ar_len_o   = ar_len_q;
  assign ar_id_o    = ar_id_q;
  assign ar_size_o  = 3'd4;

  wire do_ar = ar_valid_q && ar_ready_i;
  wire do_r  = r_valid_i && r_ready_o;

  wire [4:0] burst_c = (burst_i == 5'd0) ? 5'd1 :
                       ((burst_i > 5'(MAX_BURST)) ? 5'(MAX_BURST) : burst_i);
  wire [3:0] out_c   = (outstanding_i == 4'd0) ? 4'd1 :
                       ((outstanding_i > 4'(MAX_OUT)) ? 4'(MAX_OUT) : outstanding_i);

  wire [15:0] remain16 = (issued < target) ? (16'(target) - 16'(issued)) : 16'd0;
  wire [4:0]  this_burst_c = (remain16 == 16'd0) ? 5'd0 :
                             (remain16 < 16'(burst_c)) ? 5'(remain16[4:0]) : burst_c;
  wire issue_ok_c = running && (this_burst_c != 5'd0) && (in_flight < out_c) &&
                    (issued < target);

  wire tail_drain = running && (returned >= target) && (target != 6'd0) &&
                    (pending == 32'd0) && (in_flight != 4'd0);

  assign r_ready_o = running && ((pending != 32'd0) || tail_drain);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      issued <= '0; returned <= '0; target <= '0;
      pending <= '0; in_flight <= '0; rid_q <= '0;
      running <= 1'b0;
      ar_valid_q <= 1'b0; ar_addr_q <= '0; ar_len_q <= '0;
      ar_id_q <= '0; this_burst_q <= '0;
      done_pulse_q <= 1'b0;
      ar_txns <= '0;
    end else if (start_i) begin
      issued <= '0; returned <= '0;
      target <= beat_target_i;
      pending <= '0; in_flight <= '0; rid_q <= '0;
      running <= 1'b1;
      ar_valid_q <= 1'b0; ar_addr_q <= '0; ar_len_q <= '0;
      ar_id_q <= '0; this_burst_q <= '0;
      done_pulse_q <= 1'b0;
      ar_txns <= '0;
    end else if (running) begin
      automatic logic [5:0] iss, ret;
      automatic logic [31:0] pb;
      automatic logic [3:0] nf;
      automatic logic [5:0] bi;

      done_pulse_q <= 1'b0;
      iss = issued; ret = returned; pb = pending; nf = in_flight;

      if (do_ar) begin
        iss = iss + 6'(this_burst_q);
        pb  = pb + 32'(this_burst_q);
        nf  = nf + 4'd1;
        rid_q <= rid_q + 4'd1;
        ar_valid_q <= 1'b0;
        ar_txns <= ar_txns + 32'd1;
      end else if (!ar_valid_q) begin
        ar_valid_q   <= issue_ok_c;
        ar_addr_q    <= base_byte_i + {20'd0, iss, 4'b0000};
        this_burst_q <= this_burst_c;
        ar_len_q     <= (this_burst_c == 5'd0) ? 8'd0 : 8'(this_burst_c - 5'd1);
        ar_id_q      <= rid_q;
      end

      if (do_r) begin
        if (!tail_drain) begin
          bi = ret;
          if (bi < MAX_BEATS)
            beat_data_o[bi] <= r_data_i;
          ret = ret + 6'd1;
          pb  = pb - 32'd1;
        end
        if (r_last_i && (nf > 4'd0))
          nf = nf - 4'd1;
      end else if (r_valid_i && !r_ready_o) begin
        ; // backpressure counted at bridge
      end

      issued <= iss; returned <= ret; pending <= pb; in_flight <= nf;

      if ((target != 6'd0) && (ret >= target) && (pb == 32'd0)) begin
        running <= 1'b0;
        ar_valid_q <= 1'b0;
        done_pulse_q <= 1'b1;
      end
    end else begin
      ar_valid_q <= 1'b0;
      // This output is consumed as an event by the multi-plane wavefront.
      // Clear it in the first idle cycle so an ID completion cannot be
      // replayed while the following CUE plane is being started.
      done_pulse_q <= 1'b0;
    end
  end
endmodule
