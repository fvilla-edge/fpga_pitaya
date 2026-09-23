`timescale 1ns / 1ps
//
// Simulacion B (RedPitaya-FPGA): instancia osc_top.v REAL (no mas
// diag5_i a mano como en la Simulacion A) para probar que el modulo top
// completo -con la cadena real osc_calib -> osc_decimator ->
// bandpass_filter -> area_kurtosis_accum -> osc_trigger -> osc_aquire->
// elabora y simula sin pasar por el proyecto/IP-integrator de Vivado, y
// que el contador libre holamundo_cnt (diag5_o, agregado en la Etapa 2)
// sigue funcionando con todo eso real alrededor.
//
// Hallazgo de esta etapa: osc_top.v instancia rp_dma_s2mm.v directamente
// (no un nivel arriba como asumia el plan original), que a su vez usa
// la IP de Xilinx fifo_axi_data (FIFO Generator, sin modelo de
// simulacion en texto plano). Se resuelve con un stub de rp_dma_s2mm
// -ver sim_stub_rp_dma_s2mm.sv- ya que el DMA hacia DDR es irrelevante
// para lo que prueba esta etapa. Generar la IP real queda para cuando
// haga falta de verdad (Simulacion C/D).
//
// No se inyecta todavia una señal real de datos_campo/ (eso es trabajo
// de la Simulacion D) - el estimulo de s_axis_tdata es una rampa simple,
// solo para tener actividad en la cadena y confirmar que no se cuelga.
//
// Corre con xvlog/xelab/xsim en modo batch: ver etapa_simB_osc_top.sh.
//
module tb_osc_top_simB;

  localparam S_AXIS_DATA_BITS = 16;

  reg clk_axi = 0;
  reg clk_adc = 0;
  always #4 clk_axi = ~clk_axi; // 125MHz
  always #4 clk_adc = ~clk_adc; // mismo clock, alcanza para esta prueba

  reg axi_rstn = 0;
  reg adc_rstn = 0;

  // Estimulo de ADC: rampa simple, solo para tener actividad real en la
  // cadena de calib/decimador/filtro/acumulador/trigger/acquire.
  reg [S_AXIS_DATA_BITS-1:0] s_axis_tdata = 16'h0;
  reg                        s_axis_tvalid = 1'b0;

  always @(posedge clk_adc) begin
    if (~adc_rstn) begin
      s_axis_tdata  <= 16'h0;
      s_axis_tvalid <= 1'b0;
    end else begin
      s_axis_tdata  <= s_axis_tdata + 16'h1;
      s_axis_tvalid <= 1'b1;
    end
  end

  wire [31:0] diag1_o, diag2_o, diag3_o, diag4_o, diag5_o;
  wire [31:0] curr_wp_o;
  wire [3:0]  event_sts_o;
  wire [31:0] sts_trig_pre_cnt_o, sts_trig_post_cnt_o;
  wire        sts_trig_pre_overflow_o, sts_trig_post_overflow_o;
  wire [31:0] area_window_count_o, area_sum_abs_lo_o, area_sum_abs_hi_o;
  wire [31:0] area_sum_x2_lo_o, area_sum_x2_hi_o;
  wire [31:0] area_sum_x4_lo_o, area_sum_x4_mid_o, area_sum_x4_hi_o;
  wire [31:0] cfg_dma_sts_o, buf1_ms_cnt_o, buf2_ms_cnt_o;
  wire        trig_op, ctl_rst, trig_o, buf_sel_out, dma_intr;
  wire [31:0] m_axi_awaddr;
  wire [7:0]  m_axi_awlen;
  wire [2:0]  m_axi_awsize;
  wire [1:0]  m_axi_awburst;
  wire [2:0]  m_axi_awprot;
  wire [3:0]  m_axi_awcache;
  wire        m_axi_awvalid;
  wire [63:0] m_axi_wdata;
  wire [7:0]  m_axi_wstrb;
  wire        m_axi_wlast, m_axi_wvalid, m_axi_bready;

  osc_top #(
    .M_AXI_ADDR_BITS  (32),
    .M_AXI_DATA_BITS  (64),
    .S_AXIS_DATA_BITS (S_AXIS_DATA_BITS),
    .DEC_CNT_BITS     (17),
    .DEC_SHIFT_BITS   (4),
    .TRIG_CNT_BITS    (32),
    .EVENT_SRC_NUM    (1),
    .TRIG_SRC_NUM     (1),
    .CHAN_NUM         (1)
  ) dut (
    .clk_axi (clk_axi), .clk_adc (clk_adc), .axi_rstn (axi_rstn), .adc_rstn (adc_rstn),

    .s_axis_tdata  (s_axis_tdata), .s_axis_tvalid (s_axis_tvalid),

    .event_ip_trig  (1'b0), .event_ip_stop (1'b0), .event_ip_start (1'b0), .event_ip_reset (1'b0),
    .event_sts_o    (event_sts_o), .event_sel_i (3'h0),

    .trig_mask_i (1'b0), .cfg_trig_pre_samp_i (32'h0), .cfg_trig_post_samp_i (32'h0),
    .sts_trig_pre_cnt_o (sts_trig_pre_cnt_o), .sts_trig_post_cnt_o (sts_trig_post_cnt_o),
    .sts_trig_pre_overflow_o (sts_trig_pre_overflow_o), .sts_trig_post_overflow_o (sts_trig_post_overflow_o),
    .cfg_trig_low_level_i (16'h0), .cfg_trig_high_level_i (16'h0), .cfg_trig_edge_i (1'b0),

    .cfg_dec_factor_i (17'd1), .cfg_dec_rshift_i (4'h0), .cfg_avg_en_i (1'b0),
    // Port 2026.1: entradas nuevas de upstream, en su valor neutro
    .cfg_hres_en_i (1'b0), .cfg_legacy_calib_i (1'b0),
    .cfg_timestamp_counter_i (64'h0), .cfg_timestamp_init_i (64'h0), .cfg_timestamp_init_we_i (1'b0),
    .cfg_loopback_i (3'h0), .cfg_8bit_dat_i (1'b0),
    .cfg_calib_offset_i (16'h0), .cfg_calib_gain_i (16'h0),

    .cfg_filt_bypass_i (1'b1),
    .cfg_filt_coeff_aa_i (18'h0), .cfg_filt_coeff_bb_i (25'h0),
    .cfg_filt_coeff_kk_i (25'h0), .cfg_filt_coeff_pp_i (25'h0),

    .cfg_bp_coeff_b0_s0_i (25'sh0), .cfg_bp_coeff_b1_s0_i (25'sh0), .cfg_bp_coeff_b2_s0_i (25'sh0),
    .cfg_bp_coeff_a1_s0_i (25'sh0), .cfg_bp_coeff_a2_s0_i (25'sh0),
    .cfg_bp_coeff_b0_s1_i (25'sh0), .cfg_bp_coeff_b1_s1_i (25'sh0), .cfg_bp_coeff_b2_s1_i (25'sh0),
    .cfg_bp_coeff_a1_s1_i (25'sh0), .cfg_bp_coeff_a2_s1_i (25'sh0),

    .cfg_area_window_samples_i (32'd1024),
    .area_window_count_o (area_window_count_o),
    .area_sum_abs_lo_o (area_sum_abs_lo_o), .area_sum_abs_hi_o (area_sum_abs_hi_o),
    .area_sum_x2_lo_o (area_sum_x2_lo_o), .area_sum_x2_hi_o (area_sum_x2_hi_o),
    .area_sum_x4_lo_o (area_sum_x4_lo_o), .area_sum_x4_mid_o (area_sum_x4_mid_o), .area_sum_x4_hi_o (area_sum_x4_hi_o),

    .cfg_dma_dst_addr1_i (32'h0), .cfg_dma_dst_addr2_i (32'h0), .cfg_dma_buf_size_i (32'h1000),
    .cfg_dma_ctrl_i (32'h0), .cfg_dma_ctrl_we_i (1'b0), .cfg_dma_sts_o (cfg_dma_sts_o),

    .buf1_ms_cnt_o (buf1_ms_cnt_o), .buf2_ms_cnt_o (buf2_ms_cnt_o),

    .curr_wp_o (curr_wp_o),
    .diag1_o (diag1_o), .diag2_o (diag2_o), .diag3_o (diag3_o), .diag4_o (diag4_o), .diag5_o (diag5_o),

    .trig_ip (1'b0), .trig_op (trig_op), .ctl_rst (ctl_rst), .trig_o (trig_o),

    .buf_sel_in (1'b0), .buf_sel_out (buf_sel_out),

    .dma_intr (dma_intr),

    .m_axi_awaddr (m_axi_awaddr), .m_axi_awlen (m_axi_awlen), .m_axi_awsize (m_axi_awsize),
    .m_axi_awburst (m_axi_awburst), .m_axi_awprot (m_axi_awprot), .m_axi_awcache (m_axi_awcache),
    .m_axi_awvalid (m_axi_awvalid), .m_axi_awready (1'b1),
    .m_axi_wdata (m_axi_wdata), .m_axi_wstrb (m_axi_wstrb), .m_axi_wlast (m_axi_wlast),
    .m_axi_wvalid (m_axi_wvalid), .m_axi_wready (1'b1),
    .m_axi_bresp (2'h0), .m_axi_bvalid (1'b0), .m_axi_bready (m_axi_bready)
  );

  integer errors = 0;
  integer checks = 0;

  task automatic check_ge(input [8*32-1:0] name, input [31:0] got, input [31:0] min_exp);
    begin
      checks = checks + 1;
      if (got < min_exp) begin
        errors = errors + 1;
        $display("FAIL %0s: 0x%08h, se esperaba >= 0x%08h @ %0t", name, got, min_exp, $time);
      end else begin
        $display("OK   %0s: 0x%08h (>= 0x%08h) @ %0t", name, got, min_exp, $time);
      end
    end
  endtask

  initial begin
    // reset
    repeat (10) @(posedge clk_adc);
    axi_rstn = 1'b1;
    adc_rstn = 1'b1;

    check_ge("diag5_recien_reset", diag5_o, 32'h0);

    // dejar correr el contador un rato con la cadena real activa
    repeat (2000) @(posedge clk_adc);
    check_ge("diag5_libre_corre", diag5_o, 32'd1900);

    $display("area_window_count_o = %0d, area_sum_abs = %0d:%0d",
              area_window_count_o, area_sum_abs_hi_o, area_sum_abs_lo_o);

    if (errors == 0)
      $display("PASS: %0d checks OK, 0 errores", checks);
    else
      $display("FAIL: %0d checks, %0d errores", checks, errors);

    $finish;
  end

endmodule
