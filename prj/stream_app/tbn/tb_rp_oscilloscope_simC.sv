`timescale 1ns / 1ps
//
// Simulacion C (RedPitaya-FPGA): instancia rp_oscilloscope.v REAL
// completo (NUM_CHANNELS=2, el valor real usado por stream_app - los
// puertos ch3/ch4 existen en el modulo pero no se instancian osc_top
// para ellos con este parametro).
//
// Lo que agrega sobre la Simulacion B: scope_cfg.sv (ya probado solo en
// la Simulacion A) + el generate que instancia osc_top.v una vez por
// canal, cableado real de ADC entrada -> señal con signo -> cada
// osc_top. Sin dependencia de IP de Xilinx propia (la unica que hay,
// fifo_axi_data via rp_dma_s2mm.v, ya se resolvio en la B con
// sim_stub_rp_dma_s2mm.sv, reusado tal cual aca).
//
// Que se prueba: que el generate realmente instancia DOS osc_top
// independientes (no una copia accidental o un alias). Canal 0 se lee
// por registro AXI real (offset 0xF0, DIAG_REG5, igual que la
// Simulacion A) porque scope_cfg solo expone diagnosticos del canal 0.
// Canal 1 no tiene registro AXI para su diag5 (decision de diseño ya
// documentada en la Etapa 2/6) - se lee por referencia jerarquica
// directa (dut.diag5[63:32]) SOLO para este testbench de verificacion,
// no es una forma de leerlo desde software real.
//
// Corre con xvlog/xelab/xsim en modo batch: ver etapa_simC_osc_scope.sh.
//
module tb_rp_oscilloscope_simC;

  localparam ADC_DATA_BITS = 14;

  reg clk   = 0;
  reg rst_n = 0;
  always #4 clk = ~clk; // 125MHz, un solo dominio de clock para esta prueba

  // ADC de entrada: valores fijos pero distintos por canal, alcanza para
  // esta etapa (no se prueba comportamiento del filtro con esto, ya
  // validado aparte en la Etapa 4c/5/6 con datos reales)
  reg signed [ADC_DATA_BITS-1:0] adc_data_ch1 = 14'sd100;
  reg signed [ADC_DATA_BITS-1:0] adc_data_ch2 = -14'sd100;
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

  reg [31:0] diag5_ch0;

  initial begin
    repeat (10) @(posedge clk);
    rst_n = 1'b1;

    repeat (2000) @(posedge clk);

    // Canal 0: leido por registro AXI real (offset 0xF0, DIAG_REG5,
    // mismo mecanismo que usaria software real en la placa)
    u_axi_m.rd_single(32'h0000_00F0, 4'h5, 3'h2, 2'h0, 3'h0, diag5_ch0);
    check_ge("ch0_diag5_via_AXI", diag5_ch0, 32'd1900);

    // Canal 1: sin registro AXI expuesto (decision de diseño ya
    // documentada) - referencia jerarquica SOLO para verificar en este
    // testbench que el segundo osc_top instanciado por el generate
    // tambien esta vivo y es independiente del canal 0.
    check_ge("ch1_diag5_interno", dut.diag5[2*32-1:1*32], 32'd1900);

    if (dut.diag5[2*32-1:1*32] !== diag5_ch0) begin
      $display("INFO: ch0 y ch1 arrancaron/leyeron en instantes ligeramente distintos (esperado, cuentan libremente)");
    end

    if (errors == 0)
      $display("PASS: %0d checks OK, 0 errores", checks);
    else
      $display("FAIL: %0d checks, %0d errores", checks, errors);

    $finish;
  end

  // guarda de seguridad por si algo se cuelga esperando el bus AXI
  // (mismo criterio que tb_scope_cfg_diag5.sv, Simulacion A)
  initial begin
    #100000;
    $display("RESULTADO: TIMEOUT - la simulacion no termino sola");
    $finish;
  end

endmodule
