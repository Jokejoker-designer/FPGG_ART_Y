`timescale 1ns / 1ps
// E2R-UART-CORE-AFTER-STALL-CXSIM-00 — TB-only sent_mask stepper of hb_next + have_pending.
// Does not instantiate arty_a7_ng_native_v1_ab_soc_top or MIG.
// hb_next / have_pending copied from rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv (not edited).
module tb_e2r_uart_core_after_stall_cxsim_00;
  logic [70:0] sent_mask;

  logic calib_100, wmem_100, boot_ui_100, core_live_100;
  logic owner_100, qgo_100, soarun_100, ar_100, rbeat_100;
  logic rbusy_100, ridle_100;
  logic rvseen_100, rready1_100, ridok_100, ridbad_100, outst_100;
  logic migrv_100, cdcne_100;
  logic migar_100, ownwdma_100, cdcar_100, muxcdc_100;
  logic cdc_marf_100, cdc_sarv_100, cdc_sarr_100;
  logic ar_fifo_ne_100;
  logic sticky_m_rst_lo_100, sticky_s_rst_lo_100;
  logic cdc_sarf_100, cdc_hold_100;
  logic soaq_100, topk_100, accept_100;
  logic pack_100, bind_100, fwd_100, lm_100;
  logic bind_busy_100, wdma_busy_100, wdma_done_100, core_busy_100;
  logic tile_miss_100, tile_dst_valid_100, tile_bst_valid_100;
  logic tile_req_valid_100;
  logic mgo_f1v_100;
  logic w_stall_100, phase_valid_100;
  logic pred_nz_100, core_done_100;
  logic pred_ready;
  logic atom0_valid_100, atom1_valid_100, atom_giveup_100;

  // Copied SoC print-qualify (ATOM 69/70 stay 0).
  wire atom0_print = atom0_valid_100 || atom_giveup_100;
  wire atom1_print = atom1_valid_100 || atom_giveup_100;

  // Copied from arty_a7_ng_native_v1_ab_soc_top.sv (hb_next).
  function automatic logic [6:0] hb_next(
      input logic [70:0] mask,
      input logic mig_ok, wmem_ok, soa_ok, core_ok,
      input logic owner_ok, qgo_ok, soarun_ok, ar_ok, rbeat_ok,
      input logic rbusy_ok, ridle_ok,
      input logic rvseen_ok, rready1_ok, ridok_ok, ridbad_ok, outst_ok,
      input logic migrv_ok, cdcne_ok,
      input logic migar_ok, ownwdma_ok, cdcar_ok, muxcdc_ok,
      input logic cdc_marf_ok, cdc_sarv_ok, cdc_sarr_ok,
      input logic ar_fifo_ne_ok,
      input logic m_rst_lo_ok, s_rst_lo_ok,
      input logic cdc_sarf_ok, cdc_hold_ok,
      input logic soaq_ok, topk_ok, accept_ok,
      input logic pack_ok, bind_ok, fwd_ok, lm_ok,
      input logic bind_busy_ok, wdma_busy_ok, wdma_done_ok, core_busy_ok,
      input logic tile_miss_ok, tile_dst_ok, tile_bst_ok,
      input logic tile_req_ok, sdma_busy_ok, wdma_busy_lat_ok, wdma_own_ui_ok,
      input logic tile_dma_busy_ok, tile_dma_own_ok,
      input logic sdone_ok, mdone_ok, busy_hold_ok,
      input logic dma_st_ok, sgo_ok,
      input logic wdma_own_f1v_ok, wdma_grant_f1v_ok, rpath_idle_f1v_ok, mgo_f1v_ok,
      input logic cmd_empty_ok, sbusy_pend_ok, cmd_st_ok, cmd_rd_ok,
      input logic w_stall_ok, phase_ok,
      input logic pred_nz_ok, core_done_ok, pred_ok
  );
    if (!mask[0])  return 7'd0;
    if (mig_ok     && !mask[1])  return 7'd1;
    if (wmem_ok    && !mask[2])  return 7'd2;
    if (soa_ok     && !mask[3])  return 7'd3;
    if (core_ok    && !mask[4])  return 7'd4;
    if (owner_ok   && !mask[5])  return 7'd5;
    if (qgo_ok     && !mask[6])  return 7'd6;
    if (soarun_ok  && !mask[7])  return 7'd7;
    if (ar_ok      && !mask[8])  return 7'd8;
    if (rbeat_ok   && !mask[9])  return 7'd9;
    if (rbusy_ok   && !mask[10]) return 7'd10;
    if (ridle_ok   && !mask[11]) return 7'd11;
    if (rvseen_ok  && !mask[12]) return 7'd12;
    if (rready1_ok && !mask[13]) return 7'd13;
    if (ridok_ok   && !mask[14]) return 7'd14;
    if (ridbad_ok  && !mask[15]) return 7'd15;
    if (outst_ok   && !mask[16]) return 7'd16;
    if (migrv_ok   && !mask[17]) return 7'd17;
    if (cdcne_ok   && !mask[18]) return 7'd18;
    if (migar_ok   && !mask[19]) return 7'd19;
    if (ownwdma_ok && !mask[20]) return 7'd20;
    if (cdcar_ok   && !mask[21]) return 7'd21;
    if (muxcdc_ok  && !mask[22]) return 7'd22;
    if (cdc_marf_ok && !mask[23]) return 7'd23;
    if (cdc_sarv_ok && !mask[24]) return 7'd24;
    if (cdc_sarr_ok && !mask[25]) return 7'd25;
    if (ar_fifo_ne_ok && !mask[26]) return 7'd26;
    if (m_rst_lo_ok && !mask[27]) return 7'd27;
    if (s_rst_lo_ok && !mask[28]) return 7'd28;
    if (cdc_sarf_ok && !mask[29]) return 7'd29;
    if (cdc_hold_ok && !mask[30]) return 7'd30;
    if (soaq_ok    && !mask[31]) return 7'd31;
    if (topk_ok    && !mask[32]) return 7'd32;
    if (accept_ok  && !mask[33]) return 7'd33;
    if (pack_ok    && !mask[34]) return 7'd34;
    if (bind_ok    && !mask[35]) return 7'd35;
    if (fwd_ok     && !mask[36]) return 7'd36;
    if (lm_ok      && !mask[37]) return 7'd37;
    if (bind_busy_ok && !mask[38]) return 7'd38;
    if (wdma_busy_ok && !mask[39]) return 7'd39;
    if (wdma_done_ok && !mask[40]) return 7'd40;
    if (core_busy_ok && !mask[41]) return 7'd41;
    if (tile_miss_ok && !mask[42]) return 7'd42;
    if (tile_dst_ok  && !mask[43]) return 7'd43;
    if (tile_bst_ok  && !mask[44]) return 7'd44;
    if (tile_req_ok  && !mask[45]) return 7'd45;
    if (sdma_busy_ok && !mask[46]) return 7'd46;
    if (wdma_busy_lat_ok && !mask[47]) return 7'd47;
    if (wdma_own_ui_ok && !mask[48]) return 7'd48;
    if (tile_dma_busy_ok && !mask[49]) return 7'd49;
    if (tile_dma_own_ok  && !mask[50]) return 7'd50;
    if (sdone_ok         && !mask[56]) return 7'd56;
    if (mdone_ok         && !mask[57]) return 7'd57;
    if (busy_hold_ok     && !mask[58]) return 7'd58;
    if (dma_st_ok        && !mask[59]) return 7'd59;
    if (sgo_ok           && !mask[60]) return 7'd60;
    if (wdma_own_f1v_ok  && !mask[61]) return 7'd61;
    if (wdma_grant_f1v_ok && !mask[62]) return 7'd62;
    if (rpath_idle_f1v_ok && !mask[63]) return 7'd63;
    if (mgo_f1v_ok       && !mask[64]) return 7'd64;
    if (cmd_empty_ok     && !mask[65]) return 7'd65;
    if (sbusy_pend_ok    && !mask[66]) return 7'd66;
    if (cmd_st_ok        && !mask[67]) return 7'd67;
    if (cmd_rd_ok        && !mask[68]) return 7'd68;
    if ((atom0_valid_100 || atom_giveup_100) && !mask[69]) return 7'd69;
    if ((atom1_valid_100 || atom_giveup_100) && !mask[70]) return 7'd70;
    if (w_stall_ok && !mask[51]) return 7'd51;
    if (phase_ok   && !mask[52]) return 7'd52;
    if (pred_nz_ok && !mask[53]) return 7'd53;
    if (core_done_ok && !mask[54]) return 7'd54;
    if (pred_ok    && !mask[55]) return 7'd55;
    return 7'd0;
  endfunction

  logic have_pending;
  logic [6:0] nxt_sel;

  // Copied from SoC nxt_sel assign (pred_ok = pred_ready). bind_100 stays 0.
  assign nxt_sel = hb_next(sent_mask, calib_100, wmem_100, boot_ui_100, core_live_100,
                           owner_100, qgo_100, soarun_100, ar_100, rbeat_100,
                           rbusy_100, ridle_100,
                           rvseen_100, rready1_100, ridok_100, ridbad_100, outst_100,
                           migrv_100, cdcne_100,
                           migar_100, ownwdma_100, cdcar_100, muxcdc_100,
                           cdc_marf_100, cdc_sarv_100, cdc_sarr_100,
                           ar_fifo_ne_100,
                           sticky_m_rst_lo_100, sticky_s_rst_lo_100,
                           cdc_sarf_100, cdc_hold_100,
                           soaq_100, topk_100, accept_100,
                           pack_100, bind_100, fwd_100, lm_100,
                           bind_busy_100, wdma_busy_100, wdma_done_100, core_busy_100,
                           tile_miss_100, tile_dst_valid_100, tile_bst_valid_100,
                           tile_req_valid_100, tile_req_valid_100, tile_req_valid_100, tile_req_valid_100,
                           tile_req_valid_100, tile_req_valid_100,
                           tile_req_valid_100, tile_req_valid_100, tile_req_valid_100,
                           tile_req_valid_100, tile_req_valid_100,
                           tile_req_valid_100, tile_req_valid_100, tile_req_valid_100, tile_req_valid_100,
                           mgo_f1v_100, mgo_f1v_100, mgo_f1v_100, mgo_f1v_100,
                           w_stall_100, phase_valid_100,
                           pred_nz_100, core_done_100, pred_ready);

  // Copied from arty_a7_ng_native_v1_ab_soc_top.sv (have_pending).
  assign have_pending =
      (!sent_mask[0]) ||
      (calib_100     && !sent_mask[1]) ||
      (wmem_100      && !sent_mask[2]) ||
      (boot_ui_100   && !sent_mask[3]) ||
      (core_live_100 && !sent_mask[4]) ||
      (owner_100     && !sent_mask[5]) ||
      (qgo_100       && !sent_mask[6]) ||
      (soarun_100    && !sent_mask[7]) ||
      (ar_100        && !sent_mask[8]) ||
      (rbeat_100     && !sent_mask[9]) ||
      (rbusy_100     && !sent_mask[10]) ||
      (ridle_100     && !sent_mask[11]) ||
      (rvseen_100    && !sent_mask[12]) ||
      (rready1_100   && !sent_mask[13]) ||
      (ridok_100     && !sent_mask[14]) ||
      (ridbad_100    && !sent_mask[15]) ||
      (outst_100     && !sent_mask[16]) ||
      (migrv_100     && !sent_mask[17]) ||
      (cdcne_100     && !sent_mask[18]) ||
      (migar_100     && !sent_mask[19]) ||
      (ownwdma_100   && !sent_mask[20]) ||
      (cdcar_100     && !sent_mask[21]) ||
      (muxcdc_100    && !sent_mask[22]) ||
      (cdc_marf_100  && !sent_mask[23]) ||
      (cdc_sarv_100  && !sent_mask[24]) ||
      (cdc_sarr_100  && !sent_mask[25]) ||
      (ar_fifo_ne_100 && !sent_mask[26]) ||
      (sticky_m_rst_lo_100 && !sent_mask[27]) ||
      (sticky_s_rst_lo_100 && !sent_mask[28]) ||
      (cdc_sarf_100  && !sent_mask[29]) ||
      (cdc_hold_100  && !sent_mask[30]) ||
      (soaq_100      && !sent_mask[31]) ||
      (topk_100      && !sent_mask[32]) ||
      (accept_100    && !sent_mask[33]) ||
      (pack_100      && !sent_mask[34]) ||
      (bind_100      && !sent_mask[35]) ||
      (fwd_100       && !sent_mask[36]) ||
      (lm_100        && !sent_mask[37]) ||
      (bind_busy_100 && !sent_mask[38]) ||
      (wdma_busy_100 && !sent_mask[39]) ||
      (wdma_done_100 && !sent_mask[40]) ||
      (core_busy_100 && !sent_mask[41]) ||
      (tile_miss_100 && !sent_mask[42]) ||
      (tile_dst_valid_100 && !sent_mask[43]) ||
      (tile_bst_valid_100 && !sent_mask[44]) ||
      (tile_req_valid_100 && !sent_mask[45]) ||
      (tile_req_valid_100 && !sent_mask[46]) ||
      (tile_req_valid_100 && !sent_mask[47]) ||
      (tile_req_valid_100 && !sent_mask[48]) ||
      (tile_req_valid_100 && !sent_mask[49]) ||
      (tile_req_valid_100 && !sent_mask[50]) ||
      (tile_req_valid_100 && !sent_mask[56]) ||
      (tile_req_valid_100 && !sent_mask[57]) ||
      (tile_req_valid_100 && !sent_mask[58]) ||
      (tile_req_valid_100 && !sent_mask[59]) ||
      (tile_req_valid_100 && !sent_mask[60]) ||
      (tile_req_valid_100 && !sent_mask[61]) ||
      (tile_req_valid_100 && !sent_mask[62]) ||
      (tile_req_valid_100 && !sent_mask[63]) ||
      (tile_req_valid_100 && !sent_mask[64]) ||
      (mgo_f1v_100   && !sent_mask[65]) ||
      (mgo_f1v_100   && !sent_mask[66]) ||
      (mgo_f1v_100   && !sent_mask[67]) ||
      (mgo_f1v_100   && !sent_mask[68]) ||
      (atom0_print   && !sent_mask[69]) ||
      (atom1_print   && !sent_mask[70]) ||
      (w_stall_100   && !sent_mask[51]) ||
      (phase_valid_100 && !sent_mask[52]) ||
      (pred_nz_100   && !sent_mask[53]) ||
      (core_done_100 && !sent_mask[54]) ||
      (pred_ready    && !sent_mask[55]);

  task automatic snap(input string step_name);
    $display("STEP=%s nxt_sel=%0d have_pending=%0b mask51=%0b mask52=%0b mask54=%0b mask55=%0b w_stall=%0b phase=%0b core_done=%0b pred_ready=%0b atom0=%0b atom1=%0b giveup=%0b bind=%0b",
             step_name, nxt_sel, have_pending,
             sent_mask[51], sent_mask[52], sent_mask[54], sent_mask[55],
             w_stall_100, phase_valid_100, core_done_100, pred_ready,
             atom0_valid_100, atom1_valid_100, atom_giveup_100, bind_100);
  endtask

  task automatic send_sel(input logic [6:0] sel);
    sent_mask[sel] = 1'b1;
    #1;
  endtask

  initial begin
    logic [6:0] sel_setup, sel_a, sel_b, sel_c, sel_d;
    bit pend_a, pend_b, pend_c, pend_d;
    string verdict;
    bit classified;

    $display("E2R-UART-CORE-AFTER-STALL-CXSIM-00 START");
    $display("VEHICLE=tb_hb_next_have_pending_sent_mask_stepper NO_SOC_TOP NO_MIG C_FIX=NONE");
    $display("LAW hb_next_order=51,52,53,54,55_after_atom69_70");
    $display("LAW other_ok=0 ATOM69_70=0 bind_ok=0");
    $display("LAW core_done_raised_after_mask_51_52");
    $display("LAW pred_ready_driven_as_pred_ok bind_100_held_0");
    $display("PROGRAM=NO");

    sent_mask = 71'd0;
    calib_100 = 1'b0; wmem_100 = 1'b0; boot_ui_100 = 1'b0; core_live_100 = 1'b0;
    owner_100 = 1'b0; qgo_100 = 1'b0; soarun_100 = 1'b0; ar_100 = 1'b0; rbeat_100 = 1'b0;
    rbusy_100 = 1'b0; ridle_100 = 1'b0;
    rvseen_100 = 1'b0; rready1_100 = 1'b0; ridok_100 = 1'b0; ridbad_100 = 1'b0; outst_100 = 1'b0;
    migrv_100 = 1'b0; cdcne_100 = 1'b0;
    migar_100 = 1'b0; ownwdma_100 = 1'b0; cdcar_100 = 1'b0; muxcdc_100 = 1'b0;
    cdc_marf_100 = 1'b0; cdc_sarv_100 = 1'b0; cdc_sarr_100 = 1'b0;
    ar_fifo_ne_100 = 1'b0;
    sticky_m_rst_lo_100 = 1'b0; sticky_s_rst_lo_100 = 1'b0;
    cdc_sarf_100 = 1'b0; cdc_hold_100 = 1'b0;
    soaq_100 = 1'b0; topk_100 = 1'b0; accept_100 = 1'b0;
    pack_100 = 1'b0; bind_100 = 1'b0; fwd_100 = 1'b0; lm_100 = 1'b0;
    bind_busy_100 = 1'b0; wdma_busy_100 = 1'b0; wdma_done_100 = 1'b0; core_busy_100 = 1'b0;
    tile_miss_100 = 1'b0; tile_dst_valid_100 = 1'b0; tile_bst_valid_100 = 1'b0;
    tile_req_valid_100 = 1'b0;
    mgo_f1v_100 = 1'b0;
    w_stall_100 = 1'b0; phase_valid_100 = 1'b0;
    pred_nz_100 = 1'b0; core_done_100 = 1'b0;
    pred_ready = 1'b0;
    atom0_valid_100 = 1'b0; atom1_valid_100 = 1'b0; atom_giveup_100 = 1'b0;
    #1;

    snap("SETUP_PRE");
    sel_setup = nxt_sel;
    $display("SETUP_PRE nxt_sel=%0d (expect 0 BOOT)", sel_setup);
    send_sel(7'd0);
    snap("SETUP_BOOT_SENT");

    w_stall_100 = 1'b1;
    phase_valid_100 = 1'b1;
    core_done_100 = 1'b0;
    pred_ready = 1'b0;
    #1;
    snap("A");
    sel_a = nxt_sel;
    pend_a = have_pending;
    send_sel(7'd51);

    snap("B");
    sel_b = nxt_sel;
    pend_b = have_pending;
    send_sel(7'd52);

    core_done_100 = 1'b1;
    #1;
    snap("C");
    sel_c = nxt_sel;
    pend_c = have_pending;
    send_sel(7'd54);

    pred_ready = 1'b1;
    #1;
    snap("D");
    sel_d = nxt_sel;
    pend_d = have_pending;

    if ((sel_a != 7'd51) || (sel_b != 7'd52))
      verdict = "NO_STALL";
    else if ((sel_c == 7'd54) && (sel_d == 7'd55))
      verdict = "CORE_PRED";
    else if ((sel_c == 7'd54) && (sel_d != 7'd55))
      verdict = "CORE_ONLY";
    else
      verdict = "PRINT_DEAD";

    classified = 1'b1;

    $display("SEL_SETUP=%0d SEL_A=%0d SEL_B=%0d SEL_C=%0d SEL_D=%0d",
             sel_setup, sel_a, sel_b, sel_c, sel_d);
    $display("PEND_A=%0b PEND_B=%0b PEND_C=%0b PEND_D=%0b",
             pend_a, pend_b, pend_c, pend_d);
    $display("MASK_END 51=%0b 52=%0b 54=%0b 55=%0b",
             sent_mask[51], sent_mask[52], sent_mask[54], sent_mask[55]);
    $display("C_FIX=NONE");
    $display("BOARD_PASS=not_claimed");
    $display("EXISTENCE=not_claimed");
    $display("PROGRAM=NO");
    $display("XSIM=%s", verdict);
    $display("VERDICT_CLASS=%s", verdict);
    if (classified)
      $display("E2R_UART_CORE_AFTER_STALL_CXSIM_00_XSIM_PASS verdict=%s c_fix=NONE", verdict);
    else
      $display("E2R_UART_CORE_AFTER_STALL_CXSIM_00_XSIM_FAIL verdict=%s c_fix=NONE", verdict);
    $finish;
  end
endmodule
