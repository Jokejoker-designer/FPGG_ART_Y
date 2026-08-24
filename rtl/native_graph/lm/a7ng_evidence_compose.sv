// a7ng_evidence_compose.sv — lm_compose: structured evidence → token stream (law: a7ng-lmcompose-v0)
// Host has no final_answer port. LM-06 frozen bit is the intended silicon composer; this packs its context.
`timescale 1ns / 1ps

module a7ng_evidence_compose (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [31:0] evid_id0_i,
  input  logic [31:0] evid_id1_i,
  input  logic [31:0] evid_id2_i,
  input  logic [7:0]  entity_i,
  input  logic [7:0]  intent_i,
  output logic        busy_o,
  output logic        tok_valid_o,
  output logic [7:0]  tok_o,
  output logic        done_o,
  output logic        lm_path_active_o
);
  typedef enum logic [2:0] {S_IDLE, S_HDR, S_E0, S_E1, S_E2, S_DONE} st_t;
  st_t st;
  logic [2:0] byte_i;
  logic [31:0] cur;

  assign busy_o = (st != S_IDLE) && (st != S_DONE);
  assign lm_path_active_o = (st != S_IDLE);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE;
      tok_valid_o <= 1'b0;
      tok_o <= 8'd0;
      done_o <= 1'b0;
      byte_i <= 3'd0;
      cur <= 32'd0;
    end else begin
      tok_valid_o <= 1'b0;
      done_o <= 1'b0;
      unique case (st)
        S_IDLE: if (start_i) begin
          // header: entity, intent markers
          tok_o <= entity_i; tok_valid_o <= 1'b1; st <= S_HDR;
        end
        S_HDR: begin
          tok_o <= intent_i; tok_valid_o <= 1'b1;
          cur <= evid_id0_i; byte_i <= 3'd0; st <= S_E0;
        end
        S_E0, S_E1, S_E2: begin
          tok_o <= cur[7:0]; tok_valid_o <= 1'b1;
          cur <= {8'd0, cur[31:8]};
          if (byte_i == 3'd3) begin
            byte_i <= 3'd0;
            if (st == S_E0) begin cur <= evid_id1_i; st <= S_E1; end
            else if (st == S_E1) begin cur <= evid_id2_i; st <= S_E2; end
            else st <= S_DONE;
          end else byte_i <= byte_i + 3'd1;
        end
        S_DONE: begin done_o <= 1'b1; st <= S_IDLE; end
        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
