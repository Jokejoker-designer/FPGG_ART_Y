// a7ng_route_valid_gate.sv — U4A-R6-ROUTE-VALIDITY-00
// Probe/insert enable is the extractor bind-state valid bit.
// Numeric key selects the bucket only.
// FORBIDDEN: probe = (key != 0). Numeric zero != semantic absence.
`timescale 1ns / 1ps

module a7ng_route_valid_gate (
  input  logic        k0_valid_i,
  input  logic [15:0] k0_i,
  input  logic        k1_valid_i,
  input  logic [15:0] k1_i,
  input  logic        k2_valid_i,
  input  logic [15:0] k2_i,
  input  logic        k3_valid_i,
  input  logic [15:0] k3_i,
  output logic        probe0_o,
  output logic        probe1_o,
  output logic        probe2_o,
  output logic        probe3_o,
  output logic        insert0_o,
  output logic        insert1_o,
  output logic        insert2_o,
  output logic        insert3_o,
  output logic [11:0] bucket0_o,
  output logic [11:0] bucket1_o,
  output logic [11:0] bucket2_o,
  output logic [11:0] bucket3_o
);
  // Explicit: enable follows validity, never key numeric value.
  assign probe0_o  = k0_valid_i;
  assign probe1_o  = k1_valid_i;
  assign probe2_o  = k2_valid_i;
  assign probe3_o  = k3_valid_i;
  assign insert0_o = k0_valid_i;
  assign insert1_o = k1_valid_i;
  assign insert2_o = k2_valid_i;
  assign insert3_o = k3_valid_i;
  assign bucket0_o = k0_i[11:0];
  assign bucket1_o = k1_i[11:0];
  assign bucket2_o = k2_i[11:0];
  assign bucket3_o = k3_i[11:0];
endmodule
