`timescale 1ns / 1ps
//
// Simulacion D (dec64, para MOSTRAR el corrimiento de banda ya
// documentado, no para "aprobar" nada): mismo osc_top.v, MISMOS
// coeficientes fijos (calculados para dec32/fs=3906250Hz), pero
// alimentado con datos reales de dec64/fs=1953125Hz (extraidos por
// extraer_dec64_simD.py en tbn/vectores/dec64_simD/) - a proposito, sin
// recalcular nada. La referencia de software SI usa el fs real y
// correcto. El mismatch esperado entre HW y esa referencia es la
// limitacion conocida (README, "coeficientes fijos para decimacion 32")
// mostrandose con datos reales, no una falla nueva. Ventana ajustada a
// 97656 muestras (50ms reales a fs=1953125Hz, la mitad que a dec32) para
// no mezclar el corrimiento de banda con una ventana de duracion
// incorrecta.
//
// Ya NO hace falta la corrida de purga inicial que tenia esta etapa -
// causa raiz del artefacto de X en power-up encontrada y arreglada en
// osc_decimator.v (m_axis_tdata/m_axis_tvalid sin inicializar en su
// reset, ver comentario ahi).
//
module tb_area_kurtosis_dec64_simD;

  localparam S_AXIS_DATA_BITS = 16;
  localparam N_MUESTRAS       = 97656;
  localparam N_PARES          = 3;

  reg clk_axi = 0;
  reg clk_adc = 0;
  always #4 clk_axi = ~clk_axi;
  always #4 clk_adc = ~clk_adc;

  reg axi_rstn = 0;
  reg adc_rstn = 0;

  reg [15:0] mem_buf [0:N_MUESTRAS-1];

  reg [S_AXIS_DATA_BITS-1:0] s_axis_tdata = 16'h0;
  reg                        s_axis_tvalid = 1'b0;

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
    .M_AXI_ADDR_BITS  (32), .M_AXI_DATA_BITS (64), .S_AXIS_DATA_BITS (S_AXIS_DATA_BITS),
    .DEC_CNT_BITS (17), .DEC_SHIFT_BITS (4), .TRIG_CNT_BITS (32),
    .EVENT_SRC_NUM (1), .TRIG_SRC_NUM (1), .CHAN_NUM (1)
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
    .cfg_calib_offset_i (16'h0), .cfg_calib_gain_i (16'h8000),
    .cfg_filt_bypass_i (1'b1),
    .cfg_filt_coeff_aa_i (18'h0), .cfg_filt_coeff_bb_i (25'h0),
    .cfg_filt_coeff_kk_i (25'h0), .cfg_filt_coeff_pp_i (25'h0),
    .cfg_bp_coeff_b0_s0_i (25'sd58743),    .cfg_bp_coeff_b1_s0_i (25'sd117487),
    .cfg_bp_coeff_b2_s0_i (25'sd58743),    .cfg_bp_coeff_a1_s0_i (-25'sd1311029),
    .cfg_bp_coeff_a2_s0_i (25'sd526845),
    .cfg_bp_coeff_b0_s1_i (25'sd1048576),  .cfg_bp_coeff_b1_s1_i (-25'sd2097152),
    .cfg_bp_coeff_b2_s1_i (25'sd1048576),  .cfg_bp_coeff_a1_s1_i (-25'sd1984139),
    .cfg_bp_coeff_a2_s1_i (25'sd943367),
    .cfg_area_window_samples_i (32'd97656),
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

  integer i, p;

  task automatic correr_ventana;
    begin
      adc_rstn = 1'b0; axi_rstn = 1'b0; s_axis_tvalid = 1'b0;
      repeat (20) @(posedge clk_adc);
      adc_rstn = 1'b1; axi_rstn = 1'b1;
      repeat (20) @(posedge clk_adc);

      for (i = 0; i < N_MUESTRAS; i = i + 1) begin
        @(posedge clk_adc);
        s_axis_tdata  <= mem_buf[i];
        s_axis_tvalid <= 1'b1;
      end
      for (i = 0; i < 256; i = i + 1) begin
        @(posedge clk_adc);
        s_axis_tdata  <= 16'h0;
        s_axis_tvalid <= 1'b1;
      end
      repeat (10) @(posedge clk_adc);
    end
  endtask

  task automatic volcar_resultado(input integer idx);
    integer fh;
    begin
      fh = $fopen($sformatf("resultado_%0d.json", idx), "w");
      $fwrite(fh, "{\n");
      $fwrite(fh, "  \"window_count\": %0d,\n", area_window_count_o);
      $fwrite(fh, "  \"sum_abs_hi\": %0d, \"sum_abs_lo\": %0d,\n", area_sum_abs_hi_o, area_sum_abs_lo_o);
      $fwrite(fh, "  \"sum_x2_hi\": %0d, \"sum_x2_lo\": %0d,\n", area_sum_x2_hi_o, area_sum_x2_lo_o);
      $fwrite(fh, "  \"sum_x4_hi\": %0d, \"sum_x4_mid\": %0d, \"sum_x4_lo\": %0d\n", area_sum_x4_hi_o, area_sum_x4_mid_o, area_sum_x4_lo_o);
      $fwrite(fh, "}\n");
      $fclose(fh);
    end
  endtask

  initial begin
    for (p = 0; p < N_PARES; p = p + 1) begin
      $readmemh($sformatf("../tbn/vectores/dec64_simD/stimulus_%0d.mem", p), mem_buf);
      correr_ventana();
      $display("=== par %0d ===", p);
      $display("window_count=%0d sum_abs=%0d:%0d sum_x2=%0d:%0d sum_x4=%0d:%0d:%0d",
                area_window_count_o, area_sum_abs_hi_o, area_sum_abs_lo_o,
                area_sum_x2_hi_o, area_sum_x2_lo_o,
                area_sum_x4_hi_o, area_sum_x4_mid_o, area_sum_x4_lo_o);
      volcar_resultado(p);
    end

    $display("FIN");
    $finish;
  end

endmodule
