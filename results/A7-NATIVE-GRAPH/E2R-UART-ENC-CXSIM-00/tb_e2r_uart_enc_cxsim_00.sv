`timescale 1ns / 1ps
// E2R-UART-ENC-CXSIM-00 — TB-only replica of soc_top hex_nib + hb_char 43/62/63.
// Does not instantiate arty_a7_ng_native_v1_ab_soc_top or MIG.
// Encode copied from rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv (not edited).
module tb_e2r_uart_enc_cxsim_00;
  logic [2:0] tile_dst_100;
  logic       wdma_grant_f1v_100;
  logic       rpath_idle_f1v_100;

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

  initial begin
    logic [7:0] d_rinj, g_rinj, i_rinj;
    logic [7:0] d_rmux, g_rmux, i_rmux;
    logic [7:0] d_mux,  g_mux,  i_mux;
    logic [7:0] d_si,   g_si,   i_si;
    bit row_rinj_400, row_rmux_400, row_mux_400, row_si_400;
    bit rinj_match, rmux_match, mux_match;
    bit dest3_as_4, si_ok;
    string verdict;
    bit pass_marker;

    $display("E2R-UART-ENC-CXSIM-00 START");
    $display("VEHICLE=tb_hex_nib_hb_char_43_62_63 NO_SOC_TOP NO_MIG C_FIX=NONE");
    $display("LAW TILE_DST=hex_nib({1'b0,tile_dst_100}) sel=6'd43 i=9");
    $display("LAW WDMA_GRANT=hex_nib({3'b0,wdma_grant_f1v_100}) sel=6'd62 i=11");
    $display("LAW RPATH_IDLE=hex_nib({3'b0,rpath_idle_f1v_100}) sel=6'd63 i=11");
    $display("LAW F1w_6d64_BOOT_alias=does_not_apply");

    apply_row(3'd4, 1'b0, 1'b1);
    d_rinj = digit_dest();
    g_rinj = digit_grant();
    i_rinj = digit_idle();
    $display("ROW=RINJ drive=4,0,1 digits=%c,%c,%c", d_rinj, g_rinj, i_rinj);

    apply_row(3'd3, 1'b0, 1'b0);
    d_rmux = digit_dest();
    g_rmux = digit_grant();
    i_rmux = digit_idle();
    $display("ROW=RMUX drive=3,0,0 digits=%c,%c,%c", d_rmux, g_rmux, i_rmux);

    apply_row(3'd4, 1'b1, 1'b0);
    d_mux = digit_dest();
    g_mux = digit_grant();
    i_mux = digit_idle();
    $display("ROW=MUX drive=4,1,0 digits=%c,%c,%c", d_mux, g_mux, i_mux);

    apply_row(3'd4, 1'b0, 1'b0);
    d_si = digit_dest();
    g_si = digit_grant();
    i_si = digit_idle();
    $display("ROW=SI drive=4,0,0 digits=%c,%c,%c", d_si, g_si, i_si);

    row_rinj_400 = is_400(d_rinj, g_rinj, i_rinj);
    row_rmux_400 = is_400(d_rmux, g_rmux, i_rmux);
    row_mux_400  = is_400(d_mux,  g_mux,  i_mux);
    row_si_400   = is_400(d_si,   g_si,   i_si);

    rinj_match = (d_rinj == "4") && (g_rinj == "0") && (i_rinj == "1");
    rmux_match = (d_rmux == "3") && (g_rmux == "0") && (i_rmux == "0");
    mux_match  = (d_mux  == "4") && (g_mux  == "1") && (i_mux  == "0");
    dest3_as_4 = (d_rmux == "4");
    si_ok      = row_si_400;

    if (!si_ok || dest3_as_4) begin
      verdict = "FAIL_ENC";
      pass_marker = 1'b0;
    end else if (row_rinj_400 || row_rmux_400 || row_mux_400) begin
      verdict = "ARTIFACT";
      pass_marker = 1'b1;
    end else if (rinj_match && rmux_match && mux_match && row_si_400) begin
      verdict = "FAITHFUL";
      pass_marker = 1'b1;
    end else begin
      verdict = "FAIL_ENC";
      pass_marker = 1'b0;
    end

    $display("DIGITS_RINJ=%c,%c,%c", d_rinj, g_rinj, i_rinj);
    $display("DIGITS_RMUX=%c,%c,%c", d_rmux, g_rmux, i_rmux);
    $display("DIGITS_MUX=%c,%c,%c", d_mux, g_mux, i_mux);
    $display("DIGITS_SI=%c,%c,%c", d_si, g_si, i_si);
    $display("ROW_RINJ_400=%0b ROW_RMUX_400=%0b ROW_MUX_400=%0b ROW_SI_400=%0b",
             row_rinj_400, row_rmux_400, row_mux_400, row_si_400);
    $display("DEST3_AS_4=%0b SI_OK=%0b", dest3_as_4, si_ok);
    $display("C_FIX=NONE");
    $display("BOARD_PASS=not_claimed");
    $display("XSIM=%s", verdict);
    $display("VERDICT_CLASS=%s", verdict);
    if (pass_marker)
      $display("E2R_UART_ENC_CXSIM_00_XSIM_PASS verdict=%s c_fix=NONE", verdict);
    else
      $display("E2R_UART_ENC_CXSIM_00_XSIM_FAIL verdict=%s c_fix=NONE", verdict);
    $finish;
  end
endmodule
