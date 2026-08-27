`timescale 1ns / 1ps
// tb_e2r_telemetry_00.sv — Gate 3 event order (exact ladder)
// BOOT → MIG_OK → WMEM_OK → SOA_OK → CORE_START → BIND_DONE → LM_ACTIVE → PRED_VALID
module tb_e2r_telemetry_00;
  typedef enum int {
    EV_BOOT = 0,
    EV_MIG_OK = 1,
    EV_WMEM_OK = 2,
    EV_SOA_OK = 3,
    EV_CORE_START = 4,
    EV_BIND_DONE = 5,
    EV_LM_ACTIVE = 6,
    EV_PRED_VALID = 7
  } ev_t;

  int last_ev;
  int fail;
  bit seen [0:7];

  task automatic emit(input ev_t e, input string name);
    begin
      if (e != last_ev + 1 && !(last_ev == -1 && e == EV_BOOT)) begin
        $display("FAIL order: %s after ev=%0d (expected %0d)", name, last_ev, last_ev + 1);
        fail = 1;
      end
      if (seen[e]) begin
        $display("FAIL duplicate %s", name);
        fail = 1;
      end
      seen[e] = 1;
      last_ev = e;
      $display("EVENT %s", name);
    end
  endtask

  initial begin
    integer i;
    last_ev = -1;
    fail = 0;
    for (i = 0; i < 8; i++) seen[i] = 0;

    emit(EV_BOOT, "BOOT");
    #10 emit(EV_MIG_OK, "MIG_OK");
    #10 emit(EV_WMEM_OK, "WMEM_OK");
    #10 emit(EV_SOA_OK, "SOA_OK");
    if (!(seen[EV_MIG_OK] && seen[EV_WMEM_OK] && seen[EV_SOA_OK])) begin
      $display("FAIL firewall triad incomplete");
      fail = 1;
    end
    #10 emit(EV_CORE_START, "CORE_START");
    #10 emit(EV_BIND_DONE, "BIND_DONE");
    #10 emit(EV_LM_ACTIVE, "LM_ACTIVE");
    #10 emit(EV_PRED_VALID, "PRED_VALID");

    if (fail || last_ev != EV_PRED_VALID) begin
      $display("FAIL telemetry");
      $fatal(1);
    end
    $display("E2R_TELEMETRY_XSIM_PASS order=BOOT,MIG_OK,WMEM_OK,SOA_OK,CORE_START,BIND_DONE,LM_ACTIVE,PRED_VALID");
    $finish;
  end
endmodule
