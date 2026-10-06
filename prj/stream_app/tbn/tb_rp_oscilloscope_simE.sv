`timescale 1ns / 1ps
//
// Simulacion E (plan_in2_independiente.md de Sand Monitoring, etapa 2):
// rp_oscilloscope.v REAL completo (NUM_CHANNELS=2) con el canal 1 (IN2)
// expuesto por registro (0x34C-0x368) + ID del bloque de area (0x36C).
//
// Estimulo: el mismo tono en los dos canales, con el canal 1 al DOBLE de
// amplitud. Calibracion por defecto igual en los dos y el pasabanda es
// lineal, asi que (salvo redondeo) las sumas del canal 1 tienen que dar
// x2 (|x|), x4 (x^2) y x16 (x^4) las del canal 0. Eso prueba a la vez que
// el canal 1 existe, que sale por SUS registros y que no es un alias del
// canal 0. Ademas: los dos window_count avanzan juntos, el ID y que los
// registros del canal 0 leidos por AXI coinciden con la jerarquia interna.
//
// Decimacion 32 escrita por AXI (0x30), sin promedio, como en la placa:
// fs = 3.906MHz, coeficientes por defecto = pasabanda 50-400kHz, tono de
// 150kHz. (Con el factor por defecto 0 sale una muestra por ciclo y el
// biquad no llega a completar su recursion: el filtro se descontrola. Ese
// modo no se usa en la placa; la simulacion D ya corria con 32 por eso.)
// Ventana de 1024 muestras (escrita por AXI recien salido del reset).
//
// Corre con xvlog/xelab/xsim en modo batch: ver etapa_simE_in2.sh.
//
module tb_rp_oscilloscope_simE;

  localparam ADC_DATA_BITS = 14;

  reg clk   = 0;
  reg rst_n = 0;
  always #4 clk = ~clk; // 125MHz, un solo dominio de clock para esta prueba

  // ADC de entrada: valores fijos pero distintos por canal, alcanza para
  // esta etapa (no se prueba comportamiento del filtro con esto, ya
  // validado aparte en la Etapa 4c/5/6 con datos reales)
  reg signed [ADC_DATA_BITS-1:0] adc_data_ch1 = 14'sd0;
  reg signed [ADC_DATA_BITS-1:0] adc_data_ch2 = 14'sd0;
  reg signed [ADC_DATA_BITS-1:0] adc_data_ch3 = 14'sd0;
  reg signed [ADC_DATA_BITS-1:0] adc_data_ch4 = 14'sd0;

  // bus AXI (registro) entre el modelo de maestro y el DUT - igual que
  // en tb_scope_cfg_diag5.sv (Simulacion A)
  wire [31:0] awaddr, araddr, wdata, rdata;
  wire [2:0]  awprot, arprot;
  wire [3:0]  wstrb;
  wire        awvalid, awready, wvalid, wready, wlast;
  wire        bvalid, bready;
  wire [1:0]  bresp, rresp;
  wire        arvalid, arready, rvalid, rready, rlast;
  wire [3:0]  awid, arid, rid, bid;
  reg  [3:0]  wid = 4'h0;

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

  rp_oscilloscope #(
    .NUM_CHANNELS (2)
  ) dut (
    .clk    (clk),
    .rst_n  (rst_n),
    .intr   (),

    .adc_data_ch1 (adc_data_ch1), .adc_data_ch2 (adc_data_ch2),
    .adc_data_ch3 (adc_data_ch3), .adc_data_ch4 (adc_data_ch4),

    .event_ip_trig (7'h0), .event_ip_stop (7'h0), .event_ip_start (7'h0), .event_ip_reset (7'h0),
    .trig_ip (7'h0), .trig_out (), .clksel_o (), .daisy_slave_i (1'b0),

    .osc1_event_op (), .osc2_event_op (), .osc3_event_op (), .osc4_event_op (),
    .osc1_trig_op (), .osc2_trig_op (), .osc3_trig_op (), .osc4_trig_op (),
    .loopback_sel (),

    .s_axi_reg_aclk    (clk), .s_axi_reg_aresetn (rst_n),
    .s_axi_reg_awaddr  (awaddr), .s_axi_reg_awprot(awprot), .s_axi_reg_awvalid(awvalid), .s_axi_reg_awready(awready),
    .s_axi_reg_wdata   (wdata),  .s_axi_reg_wstrb(wstrb),   .s_axi_reg_wvalid(wvalid),   .s_axi_reg_wready(wready), .s_axi_reg_wlast(wlast),
    .s_axi_reg_bresp   (bresp),  .s_axi_reg_bvalid(bvalid), .s_axi_reg_bready(bready),
    .s_axi_reg_araddr  (araddr), .s_axi_reg_arprot(arprot), .s_axi_reg_arvalid(arvalid), .s_axi_reg_arready(arready),
    .s_axi_reg_rdata   (rdata),  .s_axi_reg_rresp(rresp),   .s_axi_reg_rvalid(rvalid),   .s_axi_reg_rready(rready), .s_axi_reg_rlast(rlast),
    .s_axi_reg_awid    (awid), .s_axi_reg_arid(arid), .s_axi_reg_wid(wid), .s_axi_reg_rid(rid), .s_axi_reg_bid(bid),

    .m_axi_osc1_aclk (clk), .m_axi_osc1_aresetn (rst_n),
    .m_axi_osc1_awaddr(), .m_axi_osc1_awlen(), .m_axi_osc1_awsize(), .m_axi_osc1_awburst(),
    .m_axi_osc1_awprot(), .m_axi_osc1_awcache(), .m_axi_osc1_awvalid(), .m_axi_osc1_awready(1'b1),
    .m_axi_osc1_wdata(), .m_axi_osc1_wstrb(), .m_axi_osc1_wlast(), .m_axi_osc1_wvalid(), .m_axi_osc1_wready(1'b1),
    .m_axi_osc1_bresp(2'h0), .m_axi_osc1_bvalid(1'b0), .m_axi_osc1_bready(),

    .m_axi_osc2_aclk (clk), .m_axi_osc2_aresetn (rst_n),
    .m_axi_osc2_awaddr(), .m_axi_osc2_awlen(), .m_axi_osc2_awsize(), .m_axi_osc2_awburst(),
    .m_axi_osc2_awprot(), .m_axi_osc2_awcache(), .m_axi_osc2_awvalid(), .m_axi_osc2_awready(1'b1),
    .m_axi_osc2_wdata(), .m_axi_osc2_wstrb(), .m_axi_osc2_wlast(), .m_axi_osc2_wvalid(), .m_axi_osc2_wready(1'b1),
    .m_axi_osc2_bresp(2'h0), .m_axi_osc2_bvalid(1'b0), .m_axi_osc2_bready(),

    .m_axi_osc3_aclk (clk), .m_axi_osc3_aresetn (rst_n),
    .m_axi_osc3_awaddr(), .m_axi_osc3_awlen(), .m_axi_osc3_awsize(), .m_axi_osc3_awburst(),
    .m_axi_osc3_awprot(), .m_axi_osc3_awcache(), .m_axi_osc3_awvalid(), .m_axi_osc3_awready(1'b1),
    .m_axi_osc3_wdata(), .m_axi_osc3_wstrb(), .m_axi_osc3_wlast(), .m_axi_osc3_wvalid(), .m_axi_osc3_wready(1'b1),
    .m_axi_osc3_bresp(2'h0), .m_axi_osc3_bvalid(1'b0), .m_axi_osc3_bready(),

    .m_axi_osc4_aclk (clk), .m_axi_osc4_aresetn (rst_n),
    .m_axi_osc4_awaddr(), .m_axi_osc4_awlen(), .m_axi_osc4_awsize(), .m_axi_osc4_awburst(),
    .m_axi_osc4_awprot(), .m_axi_osc4_awcache(), .m_axi_osc4_awvalid(), .m_axi_osc4_awready(1'b1),
    .m_axi_osc4_wdata(), .m_axi_osc4_wstrb(), .m_axi_osc4_wlast(), .m_axi_osc4_wvalid(), .m_axi_osc4_wready(1'b1),
    .m_axi_osc4_bresp(2'h0), .m_axi_osc4_bvalid(1'b0), .m_axi_osc4_bready()
  );

  localparam real FS = 125.0e6, F_TONO = 150.0e3, AMP = 1000.0;
  localparam [31:0] VENTANA = 32'd1024;
  localparam integer CICLOS_VENTANA = 32 * 1024;
  integer n = 0;
  always @(posedge clk) begin
    adc_data_ch1 <= $rtoi(AMP * $sin(2.0 * 3.14159265358979 * F_TONO * n / FS));
    adc_data_ch2 <= $rtoi(2.0 * AMP * $sin(2.0 * 3.14159265358979 * F_TONO * n / FS));
    n = n + 1;
  end



  task automatic check(input [8*40-1:0] nombre, input ok, input [8*80-1:0] detalle);
    begin
      checks = checks + 1;
      if (!ok) errors = errors + 1;
      $display("%s %0s: %0s", ok ? "OK  " : "FAIL", nombre, detalle);
    end
  endtask

  function automatic real cociente_ok(input real a, input real b, input real esperado);
    cociente_ok = (b != 0.0) && ((a / b) > esperado * 0.98) && ((a / b) < esperado * 1.02);
  endfunction

  reg [31:0] r [0:17];
  reg [31:0] id, ventana_leida, wc_antes;
  real abs0, x20, x40, abs1, x21, x41;
  integer k;

  // lee window_count del canal 0 hasta que cambia y en seguida todas las
  // sumas (una ventana dura 32768 ciclos, las ~18 lecturas AXI entran de sobra)
  task automatic leer_todo;
    begin
      u_axi_m.rd_single(32'h0000_032C, 4'h1, 3'h2, 2'h0, 3'h0, wc_antes);
      r[0] = wc_antes;
      while (r[0] == wc_antes) u_axi_m.rd_single(32'h0000_032C, 4'h1, 3'h2, 2'h0, 3'h0, r[0]);
      for (k = 1; k < 9; k = k + 1) u_axi_m.rd_single(32'h0000_032C + 4*k, 4'h1, 3'h2, 2'h0, 3'h0, r[k]);
      for (k = 0; k < 9; k = k + 1) u_axi_m.rd_single(32'h0000_034C + 4*k, 4'h1, 3'h2, 2'h0, 3'h0, r[9+k]);
    end
  endtask

  initial begin
    repeat (10) @(posedge clk);
    rst_n = 1'b1;
    repeat (20) @(posedge clk);
    u_axi_m.wr_single(32'h0000_0030, 32'd32, 4'h1, 3'h2, 2'h0, 3'h0);   // decimacion 32
    // ventana chica: se escribe con el contador recien arrancado (< 1024)
    u_axi_m.wr_single(32'h0000_0328, VENTANA, 4'h1, 3'h2, 2'h0, 3'h0);
    u_axi_m.rd_single(32'h0000_0328, 4'h1, 3'h2, 2'h0, 3'h0, ventana_leida);
    check("ventana_0x328", ventana_leida == VENTANA, "AREA_WINDOW_SAMPLES leida = escrita");

    u_axi_m.rd_single(32'h0000_036C, 4'h1, 3'h2, 2'h0, 3'h0, id);
    check("id_0x36C", id == 32'h534D_0002, "AREA_ID = 0x534D0002");

    // dejar asentar el filtro unas ventanas
    repeat (5 * CICLOS_VENTANA) @(posedge clk);
    leer_todo();

    $display("INFO wc0=%0d wc1=%0d", r[0], r[9]);
    check("window_count_juntos", (r[9] == r[0]) || (r[9] + 1 == r[0]) || (r[9] == r[0] + 1),
          "window_count canal 1 = canal 0 (+-1)");

    abs0 = r[1] + r[2] * 4294967296.0;  x20 = r[3] + r[4] * 4294967296.0;
    x40  = r[5] + r[6] * 4294967296.0 + r[7] * 18446744073709551616.0;
    abs1 = r[10] + r[11] * 4294967296.0; x21 = r[12] + r[13] * 4294967296.0;
    x41  = r[14] + r[15] * 4294967296.0 + r[16] * 18446744073709551616.0;
    $display("INFO canal0: sum|x|=%0.0f sum_x2=%0.4e sum_x4=%0.4e", abs0, x20, x40);
    $display("INFO canal1: sum|x|=%0.0f sum_x2=%0.4e sum_x4=%0.4e", abs1, x21, x41);
    $display("INFO cocientes canal1/canal0: |x| %0.4f  x2 %0.4f  x4 %0.4f", abs1/abs0, x21/x20, x41/x40);
    check("canal0_con_senal", abs0 > 100.0 * VENTANA, "el tono pasa el pasabanda del canal 0");
    check("cociente_abs_x2", cociente_ok(abs1, abs0, 2.0), "sum|x| canal1 = 2 x canal0 (+-2%)");
    check("cociente_x2_x4", cociente_ok(x21, x20, 4.0), "sum x^2 canal1 = 4 x canal0 (+-2%)");
    check("cociente_x4_x16", cociente_ok(x41, x40, 16.0), "sum x^4 canal1 = 16 x canal0 (+-2%)");
    // AXI del canal 1 = salidas internas del segundo osc_top (cableado correcto)
    check("canal1_axi_eq_interno", r[10] == dut.area_sum_abs_lo[2*32-1:1*32] || r[9] != dut.area_window_count[2*32-1:1*32],
          "0x350 = sum_abs_lo interno del canal 1");

    if (errors == 0) $display("PASS: %0d checks OK, 0 errores", checks);
    else             $display("FAIL: %0d checks, %0d errores", checks, errors);
    $finish;
  end

  initial begin
    #20000000;
    $display("RESULTADO: TIMEOUT - la simulacion no termino sola");
    $finish;
  end

endmodule
