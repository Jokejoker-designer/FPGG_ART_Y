`timescale 1ns / 1ps
// E2R-UART-SKEW-CXSIM-00 — TB-only sequential sample of hex_nib + hb_char 43 then 62/63.
// Does not instantiate arty_a7_ng_native_v1_ab_soc_top or MIG.
// Encode copied from rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv (not edited).
// Dest digit frozen at T_dst; grant/idle digits taken at T_gi after a >0 gap.
module tb_e2r_uart_skew_cxsim_00;
  logic [2:0] tile_dst_100;
  logic       wdma_grant_f1v_100;
  logic       rpath_idle_f1v_100;
  bit         occ_400;
  bit         occ_400_before_tgi;

  // Copied from arty_a7_ng_native_v1_ab_soc_top.sv (hex_nib).
  function automatic logic [7:0] hex_nib(input logic [3:0] n);
    return (n < 4'd10) ? (8'h30 + 8'(n)) : (8'h41 + 8'(n - 4'd10));
  endfunction

  // Replica of hb_char cases 43 / 62 / 63 only. F1w 6'd64→BOOT is not these lines.
  function automatic logic [7:0] hb_char(input logic [6:0] sel, input logic [6:0] i);
    unique case (sel)
      6'd43: unique case (i) // TILE_DST=H (F1o dma FSM)
        6'd0: return "T"; 6'd1: return "I"; 6'd2: return "L"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "D"; 6'd6: return "S"; 6'd7: return "T";
        6'd8: return "=";
        6'd9: return hex_nib({1'b0, tile_dst_100});
        default: return 8'h00;
      endcase
      6'd62: unique case (i) // WDMA_GRANT=H (F1v wdma_owner_grant latched)
        6'd0: return "W"; 6'd1: return "D"; 6'd2: return "M"; 6'd3: return "A";
        6'd4: return "_"; 6'd5: return "G"; 6'd6: return "R"; 6'd7: return "A";
        6'd8: return "N"; 6'd9: return "T"; 6'd10: return "=";
        6'd11: return hex_nib({3'b0, wdma_grant_f1v_100});
        default: return 8'h00;
      endcase
      6'd63: unique case (i) // RPATH_IDLE=H (F1v r_path_idle latched)
        6'd0: return "R"; 6'd1: return "P"; 6'd2: return "A"; 6'd3: return "T";
        6'd4: return "H"; 6'd5: return "_"; 6'd6: return "I"; 6'd7: return "D";
        6'd8: return "L"; 6'd9: return "E"; 6'd10: return "=";
        6'd11: return hex_nib({3'b0, rpath_idle_f1v_100});
        default: return 8'h00;
      endcase
      default: return 8'h00;
    endcase
  endfunction

  function automatic void apply_row(input logic [2:0] dest, input logic grant, input logic idle);
    tile_dst_100 = dest;
    wdma_grant_f1v_100 = grant;
    rpath_idle_f1v_100 = idle;
  endfunction

  function automatic logic [7:0] digit_dest();
    return hb_char(7'(6'd43), 7'(6'd9));
  endfunction

  function automatic logic [7:0] digit_grant();
    return hb_char(7'(6'd62), 7'(6'd11));
  endfunction

  function automatic logic [7:0] digit_idle();
    return hb_char(7'(6'd63), 7'(6'd11));
  endfunction

  function automatic bit is_400(input logic [7:0] d, input logic [7:0] g, input logic [7:0] idl);
    return (d == "4") && (g == "0") && (idl == "0");
  endfunction

  function automatic bit drive_is_400();
    return (tile_dst_100 == 3'd4) && (wdma_grant_f1v_100 == 1'b0) &&
           (rpath_idle_f1v_100 == 1'b0);
  endfunction

  task automatic reset_occ;
    apply_row(3'd0, 1'b1, 1'b1); // spacer: not dest=4 ∧ grant=0 ∧ idle=0
    #1;
    occ_400 = 1'b0;
    occ_400_before_tgi = 1'b0;
  endtask

  task automatic run_seq(
      input string row_name,
      input logic [2:0] dest_tdst, input logic grant_tdst, input logic idle_tdst,
      input logic [2:0] dest_tgi,  input logic grant_tgi,  input logic idle_tgi,
      output logic [7:0] d_print, output logic [7:0] g_print, output logic [7:0] i_print,
      output bit samecycle_before_tgi, output bit samecycle_any
  );
    reset_occ;
    apply_row(dest_tdst, grant_tdst, idle_tdst);
    #1;
    if (drive_is_400())
      occ_400 = 1'b1;
    d_print = digit_dest();
    occ_400_before_tgi = occ_400;
    #1000; // 1 µs UART-legal gap; dest already frozen
    if (drive_is_400())
      occ_400 = 1'b1;
    occ_400_before_tgi = occ_400;
    apply_row(dest_tgi, grant_tgi, idle_tgi);
    #1;
    if (drive_is_400())
      occ_400 = 1'b1;
    g_print = digit_grant();
    i_print = digit_idle();
    samecycle_before_tgi = occ_400_before_tgi;
    samecycle_any = occ_400;
    $display("ROW=%s drive_tdst=%0d,%0d,%0d drive_tgi=%0d,%0d,%0d digits=%c,%c,%c samecycle_before_tgi=%0b samecycle_any=%0b",
             row_name,
             dest_tdst, grant_tdst, idle_tdst,
             dest_tgi, grant_tgi, idle_tgi,
             d_print, g_print, i_print,
             samecycle_before_tgi, samecycle_any);
  endtask

  initial begin
    logic [7:0] d_si, g_si, i_si;
    logic [7:0] d_rinj, g_rinj, i_rinj;
    logic [7:0] d_tr, g_tr, i_tr;
    bit sc_si_b, sc_si_a;
    bit sc_rinj_b, sc_rinj_a;
    bit sc_tr_b, sc_tr_a;
    bit hold_si_400, hold_rinj_ok, trans_400;
    bit trans_never_held_400;
    string verdict;
    bit pass_marker;

    $display("E2R-UART-SKEW-CXSIM-00 START");
    $display("VEHICLE=tb_hex_nib_hb_char_43_then_62_63 NO_SOC_TOP NO_MIG C_FIX=NONE");
    $display("LAW TILE_DST=hex_nib({1'b0,tile_dst_100}) sel=6'd43 i=9 sample=T_dst");
    $display("LAW WDMA_GRANT=hex_nib({3'b0,wdma_grant_f1v_100}) sel=6'd62 i=11 sample=T_gi");
    $display("LAW RPATH_IDLE=hex_nib({3'b0,rpath_idle_f1v_100}) sel=6'd63 i=11 sample=T_gi");
    $display("LAW GAP_NS=1000 dest_frozen_at_T_dst");
    $display("LAW F1w_6d64_BOOT_alias=does_not_apply");

    apply_row(3'd0, 1'b0, 1'b0);
    #1;

    run_seq("HOLD_SI", 3'd4, 1'b0, 1'b0, 3'd4, 1'b0, 1'b0,
            d_si, g_si, i_si, sc_si_b, sc_si_a);
    run_seq("HOLD_RINJ", 3'd4, 1'b0, 1'b1, 3'd4, 1'b0, 1'b1,
            d_rinj, g_rinj, i_rinj, sc_rinj_b, sc_rinj_a);
    run_seq("TRANS_RINJ_IDLE", 3'd4, 1'b0, 1'b1, 3'd4, 1'b0, 1'b0,
            d_tr, g_tr, i_tr, sc_tr_b, sc_tr_a);

    hold_si_400 = is_400(d_si, g_si, i_si);
    hold_rinj_ok = (d_rinj == "4") && (g_rinj == "0") && (i_rinj == "1");
    trans_400 = is_400(d_tr, g_tr, i_tr);
    trans_never_held_400 = !sc_tr_b;

    if (!hold_si_400 || !hold_rinj_ok) begin
      verdict = "FAIL_SKEW";
      pass_marker = 1'b0;
    end else if (trans_400 && trans_never_held_400) begin
      verdict = "SKEW";
      pass_marker = 1'b1;
    end else if (hold_si_400 && !trans_400) begin
      verdict = "FAITHFUL_SEQ";
      pass_marker = 1'b1;
    end else begin
      verdict = "FAIL_SKEW";
      pass_marker = 1'b0;
    end

    $display("DIGITS_HOLD_SI=%c,%c,%c", d_si, g_si, i_si);
    $display("DIGITS_HOLD_RINJ=%c,%c,%c", d_rinj, g_rinj, i_rinj);
    $display("DIGITS_TRANS=%c,%c,%c", d_tr, g_tr, i_tr);
    $display("HOLD_SI_400=%0b HOLD_RINJ_OK=%0b TRANS_400=%0b",
             hold_si_400, hold_rinj_ok, trans_400);
    $display("SAMECYCLE_HOLD_SI_BEFORE=%0b SAMECYCLE_HOLD_SI_ANY=%0b", sc_si_b, sc_si_a);
    $display("SAMECYCLE_HOLD_RINJ_BEFORE=%0b SAMECYCLE_HOLD_RINJ_ANY=%0b", sc_rinj_b, sc_rinj_a);
    $display("SAMECYCLE_TRANS_BEFORE_TGI=%0b SAMECYCLE_TRANS_ANY=%0b TRANS_NEVER_HELD_400=%0b",
             sc_tr_b, sc_tr_a, trans_never_held_400);
    $display("C_FIX=NONE");
    $display("BOARD_PASS=not_claimed");
    $display("XSIM=%s", verdict);
    $display("VERDICT_CLASS=%s", verdict);
    if (pass_marker)
      $display("E2R_UART_SKEW_CXSIM_00_XSIM_PASS verdict=%s c_fix=NONE", verdict);
    else
      $display("E2R_UART_SKEW_CXSIM_00_XSIM_FAIL verdict=%s c_fix=NONE", verdict);
    $finish;
  end
endmodule
