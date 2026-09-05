// tb_u4ar6_valid_key0.sv — protocol: valid=1,key=0 MUST probe; valid=0,key=0 must not.
// Proves the gate is not secretly implementing key!=0. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_u4ar6_valid_key0;
  logic        k0v, k1v, k2v, k3v;
  logic [15:0] k0, k1, k2, k3;
  logic        p0, p1, p2, p3;
  logic        i0, i1, i2, i3;
  logic [11:0] b0, b1, b2, b3;
  integer fail;

  a7ng_route_valid_gate dut (
    .k0_valid_i(k0v), .k0_i(k0),
    .k1_valid_i(k1v), .k1_i(k1),
    .k2_valid_i(k2v), .k2_i(k2),
    .k3_valid_i(k3v), .k3_i(k3),
    .probe0_o(p0), .probe1_o(p1), .probe2_o(p2), .probe3_o(p3),
    .insert0_o(i0), .insert1_o(i1), .insert2_o(i2), .insert3_o(i3),
    .bucket0_o(b0), .bucket1_o(b1), .bucket2_o(b2), .bucket3_o(b3)
  );

  initial begin
    fail = 0;
    k0v = 0; k1v = 0; k2v = 0; k3v = 0;
    k0 = 0; k1 = 0; k2 = 0; k3 = 0;
    #1;
    // Case A: valid=1, key=0 on T2 → MUST probe, bucket 0.
    k2v = 1'b1; k2 = 16'h0000;
    #1;
    if (p2 !== 1'b1) begin
      $display("FIRST_DIVERGENCE CASE_A valid1_key0 did not probe (secret key!=0?)");
      fail = fail + 1;
    end
    if (i2 !== 1'b1) begin
      $display("FIRST_DIVERGENCE CASE_A valid1_key0 did not insert");
      fail = fail + 1;
    end
    if (b2 !== 12'h000) begin
      $display("FIRST_DIVERGENCE CASE_A bucket=%h", b2);
      fail = fail + 1;
    end
    $display("CASE_A valid=1 key=0 probe=%0d insert=%0d bucket=%h", p2, i2, b2);

    // Case B: valid=0, key=0 → do not probe.
    k2v = 1'b0; k2 = 16'h0000;
    #1;
    if (p2 !== 1'b0) begin
      $display("FIRST_DIVERGENCE CASE_B valid0_key0 probed");
      fail = fail + 1;
    end
    if (i2 !== 1'b0) begin
      $display("FIRST_DIVERGENCE CASE_B valid0_key0 inserted");
      fail = fail + 1;
    end
    $display("CASE_B valid=0 key=0 probe=%0d insert=%0d", p2, i2);

    // Case C: valid=0, key!=0 → still no probe (not inverted key test).
    k2v = 1'b0; k2 = 16'h00A7;
    #1;
    if (p2 !== 1'b0) begin
      $display("FIRST_DIVERGENCE CASE_C valid0_key_nz probed — gate used key!=0");
      fail = fail + 1;
    end
    $display("CASE_C valid=0 key=00a7 probe=%0d bucket=%h", p2, b2);

    // Case D: valid=1, key!=0 → probe unchanged bucket law.
    k2v = 1'b1; k2 = 16'h1234;
    #1;
    if (p2 !== 1'b1) begin
      $display("FIRST_DIVERGENCE CASE_D valid1_key_nz no probe");
      fail = fail + 1;
    end
    if (b2 !== 12'h234) begin
      $display("FIRST_DIVERGENCE CASE_D bucket=%h", b2);
      fail = fail + 1;
    end
    $display("CASE_D valid=1 key=1234 probe=%0d bucket=%h", p2, b2);

    // Case E: all-valid=0 → no table probed (UNKNOWN, no full scan).
    k0v = 0; k1v = 0; k2v = 0; k3v = 0;
    k0 = 0; k1 = 0; k2 = 0; k3 = 0;
    #1;
    if (p0|p1|p2|p3) begin
      $display("FIRST_DIVERGENCE CASE_E fully_unknown probed");
      fail = fail + 1;
    end
    $display("CASE_E all_valid=0 probes=%0d%0d%0d%0d", p0, p1, p2, p3);

    if (fail != 0) begin
      $display("U4A_R6_PROTOCOL_FAIL fail=%0d", fail);
      $finish;
    end
    $display("U4A_R6_PROTOCOL_PASS");
    $finish;
  end
endmodule
