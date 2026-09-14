`timescale 1ns / 1ps
//
// Etapa 2 (RedPitaya-FPGA): testbench dirigido, standalone, para validar
// que el registro nuevo DIAG_REG5 (offset 0xF0, ver scope_cfg.sv) se lee
// bien por AXI y no choca con los diagnosticos existentes (DIAG_REG1-4,
// 0xE0-0xEC).
//
// Instancia SOLO scope_cfg.sv (el decodificador de registros AXI) + el
// modelo de maestro AXI que ya existe en tbn/ (axi_master_model.sv) -no
// se instancia rp_oscilloscope.v completo porque sus rutas de DMA usan
// un core Xilinx FIFO Generator via IP catalog, que no se puede simular
// standalone con xvlog/xelab/xsim sin pasar antes por generacion de IP
// en un proyecto Vivado (ver seccion "Simulacion" del README para el
// plan de como llegar a simular el diseño completo mas adelante).
//
// Corre con xvlog/xelab/xsim en modo batch, sin Vivado GUI:
//   ver etapa2_sim_diag5.sh en la raiz del repo.
//
module tb_scope_cfg_diag5;

  reg clk   = 0;
  reg rst_n = 0;
  always #4 clk = ~clk; // 125MHz

  // patrones de prueba, uno por diagnostico, faciles de distinguir a ojo
  reg [31:0] diag1_i = 32'hAAAA_0001;
  reg [31:0] diag2_i = 32'hAAAA_0002;
  reg [31:0] diag3_i = 32'hAAAA_0003;
  reg [31:0] diag4_i = 32'hAAAA_0004;
  reg [31:0] diag5_i = 32'hAAAA_0005;

  // bus AXI (registro) entre el modelo de maestro y el DUT
  wire [31:0] awaddr, araddr, wdata, rdata;
  wire [2:0]  awprot;
  wire [2:0]  arprot;
  wire [3:0]  wstrb;
  wire        awvalid, awready, wvalid, wready, wlast;
  wire        bvalid, bready;
  wire [1:0]  bresp, rresp;
  wire        arvalid, arready, rvalid, rready, rlast;
  wire [3:0]  awid, arid, rid, bid;
  reg  [3:0]  wid = 4'h0;

  integer errors = 0;
  integer checks = 0;

  task automatic check32(input [8*32-1:0] name, input [31:0] got, input [31:0] exp);
    begin
      checks = checks + 1;
      if (got !== exp) begin
        errors = errors + 1;
        $display("FAIL %0s: se leyo 0x%08h, se esperaba 0x%08h @ %0t", name, got, exp, $time);
      end else begin
        $display("OK   %0s: 0x%08h @ %0t", name, got, $time);
      end
    end
  endtask

  axi_master_model #(.AW(32), .DW(32), .IW(4), .LW(4)) u_axi_m (
    .aclk_i    (clk),
    .arstn_i   (rst_n),
    .awid_o    (awid), .awlen_o(), .awsize_o(), .awburst_o(), .awcache_o(),
    .awaddr_o  (awaddr), .awprot_o(awprot), .awvalid_o(awvalid), .awready_i(awready), .awlock_o(),
    .wdata_o   (wdata), .wstrb_o(wstrb), .wlast_o(wlast), .wvalid_o(wvalid), .wready_i(wready),
    .bid_i     (bid), .bresp_i(bresp), .bvalid_i(bvalid), .bready_o(bready),
    .arid_o    (arid), .arlen_o(), .arsize_o(), .arburst_o(), .arprot_o(arprot), .arcache_o(),
    .arvalid_o (arvalid), .araddr_o(araddr), .arlock_o(), .arready_i(arready),
    .rid_i     (rid), .rdata_i(rdata), .rresp_i(rresp), .rvalid_i(rvalid), .rlast_i(rlast), .rready_o(rready)
  );

  scope_cfg #(
    .ID_WIDTHS     (4),
    .EVENT_SRC_NUM (1),
    .TRIG_SRC_NUM  (1)
  ) dut (
    .s_axi_reg_aclk    (clk),
    .s_axi_reg_aresetn (rst_n),
    .s_axi_reg_awaddr  (awaddr), .s_axi_reg_awprot(awprot), .s_axi_reg_awvalid(awvalid), .s_axi_reg_awready(awready),
    .s_axi_reg_wdata   (wdata),  .s_axi_reg_wstrb(wstrb),   .s_axi_reg_wvalid(wvalid),   .s_axi_reg_wready(wready), .s_axi_reg_wlast(wlast),
    .s_axi_reg_bresp   (bresp),  .s_axi_reg_bvalid(bvalid), .s_axi_reg_bready(bready),
    .s_axi_reg_araddr  (araddr), .s_axi_reg_arprot(arprot), .s_axi_reg_arvalid(arvalid), .s_axi_reg_arready(arready),
    .s_axi_reg_rdata   (rdata),  .s_axi_reg_rresp(rresp),   .s_axi_reg_rvalid(rvalid),   .s_axi_reg_rready(rready), .s_axi_reg_rlast(rlast),
    .s_axi_reg_awid    (awid), .s_axi_reg_arid(arid), .s_axi_reg_wid(wid), .s_axi_reg_rid(rid), .s_axi_reg_bid(bid),

    .clk_axi_i  (clk), .clk_adc_i (clk), .axi_rstn_i (rst_n), .adc_rstn_i (rst_n),

    .cfg_event_op_trig_o(), .cfg_event_op_stop_o(), .cfg_event_op_start_o(), .cfg_event_op_reset_o(),
    .cfg_event_sts_i (4'h0), .cfg_event_sel_o(),
    .cfg_trig_mask_o(), .cfg_trig_pre_samp_o(), .cfg_trig_post_samp_o(),
    .sts_trig_pre_cnt_i(32'h0), .sts_trig_post_cnt_i(32'h0),
    .sts_trig_pre_overflow_i(1'b0), .sts_trig_post_overflow_i(1'b0),
    .cfg_trig_low_level_o(), .cfg_trig_high_level_o(), .cfg_trig_edge_o(),

    .cfg_dec_factor_o(), .cfg_dec_rshift_o(), .cfg_avg_en_o(), .cfg_loopback_o(), .cfg_8bit_dat_o(),
    .clksel_o(), .daisy_slave_i(1'b0),

    .cfg_filt_bypass_o(), .cfg_dma_buf_size_o(), .cfg_dma_ctrl_o(), .cfg_dma_ctrl_we_o(),
    .cfg_dma_sts_i(32'h0),

    .cfg_calib_offset_o(), .cfg_calib_gain_o(),
    .cfg_filt_coeff_aa_o(), .cfg_filt_coeff_bb_o(), .cfg_filt_coeff_kk_o(), .cfg_filt_coeff_pp_o(),
    .cfg_dma_dst_addr1_o(), .cfg_dma_dst_addr2_o(),

    .buf1_ms_cnt_i(128'h0), .buf2_ms_cnt_i(128'h0), .curr_wp_i(128'h0),

    .diag1_i (diag1_i), .diag2_i (diag2_i), .diag3_i (diag3_i), .diag4_i (diag4_i), .diag5_i (diag5_i)
  );

  reg [31:0] rd;

  initial begin
    rst_n = 0;
    repeat (10) @(posedge clk);
    rst_n = 1;
    repeat (5) @(posedge clk);

    // 1. Los 4 diagnosticos existentes siguen leyendose bien (nada roto)
    u_axi_m.rd_single(32'h0000_00E0, 4'h1, 3'h2, 2'h0, 3'h0, rd); check32("DIAG_REG1 (0xE0)", rd, diag1_i);
    u_axi_m.rd_single(32'h0000_00E4, 4'h2, 3'h2, 2'h0, 3'h0, rd); check32("DIAG_REG2 (0xE4)", rd, diag2_i);
    u_axi_m.rd_single(32'h0000_00E8, 4'h3, 3'h2, 2'h0, 3'h0, rd); check32("DIAG_REG3 (0xE8)", rd, diag3_i);
    u_axi_m.rd_single(32'h0000_00EC, 4'h4, 3'h2, 2'h0, 3'h0, rd); check32("DIAG_REG4 (0xEC)", rd, diag4_i);

    // 2. El registro nuevo (DIAG_REG5, 0xF0) lee el valor correcto
    u_axi_m.rd_single(32'h0000_00F0, 4'h5, 3'h2, 2'h0, 3'h0, rd); check32("DIAG_REG5 (0xF0)", rd, diag5_i);

    // 3. Sigue el valor en vivo (no quedo latcheado en el primer read)
    diag5_i = 32'h5555_AAAA;
    repeat (3) @(posedge clk);
    u_axi_m.rd_single(32'h0000_00F0, 4'h6, 3'h2, 2'h0, 3'h0, rd); check32("DIAG_REG5 tras cambiar diag5_i", rd, diag5_i);

    // 4. No hay aliasing: la siguiente direccion libre (0xF4) NO devuelve diag5_i
    u_axi_m.rd_single(32'h0000_00F4, 4'h7, 3'h2, 2'h0, 3'h0, rd);
    checks = checks + 1;
    if (rd === diag5_i) begin
      errors = errors + 1;
      $display("FAIL 0xF4 (direccion sin mapear) devolvio el mismo valor que DIAG_REG5 - posible aliasing @ %0t", $time);
    end else begin
      $display("OK   0xF4 (direccion sin mapear) no aliasea con DIAG_REG5 (leyo 0x%08h) @ %0t", rd, $time);
    end

    $display("--------------------------------------------------------------");
    if (errors == 0)
      $display("RESULTADO: TODOS LOS CHECKS PASARON (%0d/%0d)", checks, checks);
    else
      $display("RESULTADO: %0d CHECKS FALLARON de %0d", errors, checks);
    $display("--------------------------------------------------------------");

    $finish;
  end

  // guarda de seguridad por si algo se cuelga esperando el bus AXI
  initial begin
    #100000;
    $display("RESULTADO: TIMEOUT - la simulacion no termino sola");
    $finish;
  end

endmodule
