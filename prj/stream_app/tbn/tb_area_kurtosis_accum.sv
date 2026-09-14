`timescale 1ns / 1ps
//
// Etapa 5 (RedPitaya-FPGA): testbench dirigido, standalone, para
// area_kurtosis_accum.v. Ventana chica (4 muestras) para poder chequear
// varias ventanas completas a mano en poco tiempo de simulacion.
//
// Corre con xvlog/xelab/xsim en modo batch, sin GUI: ver
// etapa5_sim_area_kurtosis.sh en la raiz del repo.
//
module tb_area_kurtosis_accum;

  localparam WINDOW = 4;

  reg clk = 0;
  always #4 clk = ~clk;

  reg rst_n = 0;
  reg signed [15:0] s_axis_tdata  = 16'h0;
  reg               s_axis_tvalid = 1'b0;
  reg [31:0]        cfg_window_samples = WINDOW;

  wire [39:0] sum_abs;
  wire [51:0] sum_x2;
  wire [83:0] sum_x4;
  wire [31:0] window_count;

  area_kurtosis_accum #(.S_AXIS_DATA_BITS(16)) dut (
    .clk                (clk),
    .rst_n              (rst_n),
    .s_axis_tdata       (s_axis_tdata),
    .s_axis_tvalid      (s_axis_tvalid),
    .cfg_window_samples (cfg_window_samples),
    .sum_abs            (sum_abs),
    .sum_x2             (sum_x2),
    .sum_x4             (sum_x4),
    .window_count       (window_count)
  );

  integer errors = 0;
  integer checks = 0;

  // ventana 1: 10, -20, 30, -40  -> |x|: 10+20+30+40=100
  //            x^2: 100+400+900+1600=3000
  //            x^4: 10000+160000+810000+2560000=3540000
  // ventana 2: 100, 100, 100, 100 -> abs=400, x2=40000, x4=400000000
  localparam integer V1[0:3] = '{10, -20, 30, -40};
  localparam integer V2[0:3] = '{100, 100, 100, 100};

  task automatic feed(input integer val);
    begin
      @(negedge clk);
      s_axis_tdata  = val[15:0];
      s_axis_tvalid = 1'b1;
      @(posedge clk);
      #1;
    end
  endtask

  task automatic check_window(input [39:0] exp_abs, input [51:0] exp_x2, input [83:0] exp_x4, input [31:0] exp_cnt);
    begin
      checks = checks + 1;
      if ((sum_abs !== exp_abs) || (sum_x2 !== exp_x2) || (sum_x4 !== exp_x4) || (window_count !== exp_cnt)) begin
        errors = errors + 1;
        $display("FAIL @ %0t: sum_abs=%0d(esp %0d) sum_x2=%0d(esp %0d) sum_x4=%0d(esp %0d) window_count=%0d(esp %0d)",
                  $time, sum_abs, exp_abs, sum_x2, exp_x2, sum_x4, exp_x4, window_count, exp_cnt);
      end
    end
  endtask

  integer i;
  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;

    for (i = 0; i < 4; i = i + 1) feed(V1[i]);
    check_window(40'd100, 52'd3000, 84'd3540000, 32'd1);

    for (i = 0; i < 4; i = i + 1) feed(V2[i]);
    check_window(40'd400, 52'd40000, 84'd400000000, 32'd2);

    // ventana con huecos de tvalid=0 en el medio - no deben contar como muestra
    @(negedge clk); s_axis_tdata = 16'd5; s_axis_tvalid = 1'b1; @(posedge clk); #1;
    @(negedge clk); s_axis_tvalid = 1'b0; @(posedge clk); #1; // no cuenta
    @(negedge clk); s_axis_tvalid = 1'b0; @(posedge clk); #1; // no cuenta
    @(negedge clk); s_axis_tdata = 16'd5; s_axis_tvalid = 1'b1; @(posedge clk); #1;
    @(negedge clk); s_axis_tdata = 16'd5; s_axis_tvalid = 1'b1; @(posedge clk); #1;
    @(negedge clk); s_axis_tdata = 16'd5; s_axis_tvalid = 1'b1; @(posedge clk); #1;
    // 4 muestras validas de valor 5: abs=20, x2=100, x4=2500
    check_window(40'd20, 52'd100, 84'd2500, 32'd3);

    // ------------------------------------------------------------------
    // Ventana de tamaño REAL (195312 muestras, dec32/50ms) a fondo de
    // escala (32767) - prueba que los anchos de los acumuladores
    // (dimensionados para hasta 2^20 muestras, con margen) no truncan
    // en el caso real, no solo en el analisis a mano.
    // ------------------------------------------------------------------
    cfg_window_samples = 195312;
    begin : ventana_real
      integer k;
      reg [39:0] exp_abs;
      reg [51:0] exp_x2;
      reg [83:0] exp_x4;
      exp_abs = 40'd195312 * 40'd32767;
      exp_x2  = 52'd195312 * (52'd32767 * 52'd32767);
      exp_x4  = 84'd195312 * ((84'd32767 * 84'd32767) * (84'd32767 * 84'd32767));
      for (k = 0; k < 195312; k = k + 1) feed(32767);
      check_window(exp_abs, exp_x2, exp_x4, 32'd4);
    end

    $display("--------------------------------------------------------------");
    if (errors == 0)
      $display("RESULTADO: TODOS LOS CHECKS PASARON (%0d/%0d)", checks, checks);
    else
      $display("RESULTADO: %0d CHECKS FALLARON de %0d", errors, checks);
    $display("--------------------------------------------------------------");
    $finish;
  end

  initial begin
    #5_000_000; // la ventana de tamaño real (195312 muestras) sola ya son ~1.6ms
    $display("RESULTADO: TIMEOUT - la simulacion no termino sola");
    $finish;
  end

endmodule
