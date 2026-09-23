`timescale 1ns / 1ps
//
// Simulacion D (RedPitaya-FPGA): inyecta una captura REAL de arena (de
// datos_campo/ en Sand Monitoring, extraida por
// tbn/vectores/extraer_datos_reales_simD.py) como estimulo de ADC contra
// osc_top.v REAL completo (misma base que la Simulacion B), y compara
// el area/kurtosis que da el hardware simulado (bandpass_filter.v +
// area_kurtosis_accum.v juntos, Etapas 4c y 5) contra la referencia que
// calcula el software real (area_kurtosis.py), sobre el MISMO segmento
// exacto de datos.
//
// Corrige el plan original: no hace falta system_model.sv ni tocar el
// Makefile - el area/kurtosis se lee por registro AXI directo (ya
// probado en A/B/C), no por DMA, asi que ya se puede inyectar datos
// reales sin simular el procesador. Se instancia osc_top.v directo
// (como en B) en vez de rp_oscilloscope.v (como en C) porque lo nuevo
// a probar aca es la NUMERICA del filtro+acumulador contra datos
// reales, no el cableado AXI multi-canal (ya cerrado en C) - se leen
// los area_*_o directamente como puertos del DUT, sin pasar por
// scope_cfg.sv.
//
// Los coeficientes del pasabanda son constantes fijas en este
// testbench, copiadas de los defaults reales de scope_cfg.sv (Etapa
// 4c/6) porque osc_top.v standalone no tiene registro con reset propio
// (ese default vive en scope_cfg.sv, que no se instancia aca) - ver
// README para el valor de cada uno.
//
// Corre con xvlog/xelab/xsim en modo batch: ver etapa_simD_area_kurtosis.sh.
// Requiere haber corrido antes tbn/vectores/extraer_datos_reales_simD.py
// (genera stimulus_evento_simD.mem y stimulus_reposo_simD.mem).
//
module tb_area_kurtosis_simD;

  localparam S_AXIS_DATA_BITS = 16;
  localparam N_MUESTRAS       = 195312; // 50ms a fs=3906250Hz, igual al default de AREA_WINDOW_SAMPLES

  reg clk_axi = 0;
  reg clk_adc = 0;
  always #4 clk_axi = ~clk_axi;
  always #4 clk_adc = ~clk_adc;

  reg axi_rstn = 0;
  reg adc_rstn = 0;

  reg [15:0] mem_evento [0:N_MUESTRAS-1];
  reg [15:0] mem_reposo [0:N_MUESTRAS-1];

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

    // decimador en passthrough (factor 1): los datos ya vienen decimados
    // por 32 desde el archivo real (fs=3906250Hz, igual que en la placa)
    .cfg_dec_factor_i (17'd1), .cfg_dec_rshift_i (4'h0), .cfg_avg_en_i (1'b0),
    // Port 2026.1: entradas nuevas de upstream, en su valor neutro
    .cfg_hres_en_i (1'b0), .cfg_legacy_calib_i (1'b0),
    .cfg_timestamp_counter_i (64'h0), .cfg_timestamp_init_i (64'h0), .cfg_timestamp_init_we_i (1'b0),
    .cfg_loopback_i (3'h0), .cfg_8bit_dat_i (1'b0),
    // cfg_calib_gain_i=0 zaría la señal por completo (es un multiplicador,
    // no un offset) - se usa el default real de scope_cfg.sv (ganancia
    // unidad), no un "0 total" como en B/C donde el valor no importaba
    .cfg_calib_offset_i (16'h0), .cfg_calib_gain_i (16'h8000),

    .cfg_filt_bypass_i (1'b1), // filtro viejo (osc_filter, pre-Etapa3) en bypass, no es el pasabanda real
    .cfg_filt_coeff_aa_i (18'h0), .cfg_filt_coeff_bb_i (25'h0),
    .cfg_filt_coeff_kk_i (25'h0), .cfg_filt_coeff_pp_i (25'h0),

    // Coeficientes reales del pasabanda (Etapa 4c/6) - copiados de los
    // defaults de scope_cfg.sv, ver README
    .cfg_bp_coeff_b0_s0_i (25'sd58743),    .cfg_bp_coeff_b1_s0_i (25'sd117487),
    .cfg_bp_coeff_b2_s0_i (25'sd58743),    .cfg_bp_coeff_a1_s0_i (-25'sd1311029),
    .cfg_bp_coeff_a2_s0_i (25'sd526845),
    .cfg_bp_coeff_b0_s1_i (25'sd1048576),  .cfg_bp_coeff_b1_s1_i (-25'sd2097152),
    .cfg_bp_coeff_b2_s1_i (25'sd1048576),  .cfg_bp_coeff_a1_s1_i (-25'sd1984139),
    .cfg_bp_coeff_a2_s1_i (25'sd943367),

    .cfg_area_window_samples_i (32'd195312),
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

  integer i;

  task automatic correr_ventana(input [8*16-1:0] nombre, input use_evento);
    begin
      // reset limpio entre ventanas: el acumulador arranca en 0 real
      // (no X) y no arrastra nada de la corrida anterior
      adc_rstn = 1'b0;
      axi_rstn = 1'b0;
      s_axis_tvalid = 1'b0;
      repeat (20) @(posedge clk_adc);
      adc_rstn = 1'b1;
      axi_rstn = 1'b1;
      repeat (20) @(posedge clk_adc); // asentar los resets registrados en cascada (rstn_dec, etc.)

      for (i = 0; i < N_MUESTRAS; i = i + 1) begin
        @(posedge clk_adc);
        s_axis_tdata  <= use_evento ? mem_evento[i] : mem_reposo[i];
        s_axis_tvalid <= 1'b1;
      end

      // Cola de relleno (valida, en 0): la ventana de conteo del
      // acumulador necesita exactamente N_MUESTRAS muestras VALIDAS en
      // su propia entrada, que esta unos ciclos rio abajo del estimulo
      // (latencia de llenado de osc_calib/osc_decimator/bandpass_biquad
      // x2). Sin esta cola, la ventana queda a mitad de camino y nunca
      // publica (sum_*_o se queda en el valor de reset, 0 - no es X
      // porque no es un bug, es la ventana sin terminar). 256 ciclos de
      // sobra (la latencia real es de un puñado de ciclos) diluyen la
      // ventana en <=256/195312 = 0.13%, despreciable para esta
      // comparacion.
      for (i = 0; i < 256; i = i + 1) begin
        @(posedge clk_adc);
        s_axis_tdata  <= 16'h0;
        s_axis_tvalid <= 1'b1;
      end
      repeat (10) @(posedge clk_adc); // drenar el ultimo tramo de la cadena

      $display("=== %0s ===", nombre);
      $display("window_count=%0d", area_window_count_o);
      $display("sum_abs = %0d:%0d", area_sum_abs_hi_o, area_sum_abs_lo_o);
      $display("sum_x2  = %0d:%0d", area_sum_x2_hi_o, area_sum_x2_lo_o);
      $display("sum_x4  = %0d:%0d:%0d", area_sum_x4_hi_o, area_sum_x4_mid_o, area_sum_x4_lo_o);
    end
  endtask

  task automatic volcar_resultado(input [8*16-1:0] nombre_archivo);
    integer fh;
    begin
      fh = $fopen({"resultado_", nombre_archivo, ".json"}, "w");
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
    $readmemh("../tbn/vectores/stimulus_evento_simD.mem", mem_evento);
    $readmemh("../tbn/vectores/stimulus_reposo_simD.mem", mem_reposo);

    // La corrida de "purga" que hacia falta aca (la primerisima corrida
    // tras el power-up de la simulacion dejaba el biquad en X aunque
    // rst_n ya estuviera en 1) ya NO hace falta: causa raiz encontrada y
    // arreglada en osc_decimator.v (m_axis_tdata/m_axis_tvalid sin
    // inicializar en su reset, ver comentario ahi) - confirmado corriendo
    // EVENTO como primera corrida real de la simulacion, sin purga
    // previa, y da resultado limpio.
    correr_ventana("EVENTO", 1'b1);
    volcar_resultado("evento");
    correr_ventana("REPOSO", 1'b0);
    volcar_resultado("reposo");

    $display("FIN");
    $finish;
  end

endmodule
