`timescale 1ns / 1ps
//
// Etapa 4c (RedPitaya-FPGA): testbench dirigido, standalone, para
// bandpass_filter.v (pasabanda real, 50-400kHz, Butterworth orden 2,
// 2 secciones biquad en cascada, fs=3906250Hz - la señal YA decimada,
// el filtro vive DESPUES del decimador).
//
// Vectores golden generados con un modelo Python que replica EXACTO la
// misma aritmetica de punto fijo del RTL (mismos coeficientes
// cuantizados, mismo redondeo, misma saturacion) - ver
// tbn/vectores/generar_etapa4c.py. No es comparacion contra el filtro
// ideal en punto flotante - es bit exacta contra "lo que este punto
// fijo deberia dar", igual criterio que la Etapa 4b.
//
// Corre con xvlog/xelab/xsim en modo batch, sin GUI: ver
// etapa4c_sim_bandpass.sh en la raiz del repo.
//
module tb_bandpass_filter;

  localparam LATENCY = 3;  // 2 secciones en cascada: no es 1+1=2 (conectar la
                            // salida registrada de una seccion directo a la
                            // entrada registrada de la otra agrega un ciclo
                            // extra respecto a la suma ingenua - confirmado
                            // empiricamente, ver commit de esta etapa)

  reg clk = 0;
  always #4 clk = ~clk;

  reg rst_n = 0;
  reg  [15:0] s_axis_tdata  = 16'h0;
  reg         s_axis_tvalid = 1'b0;
  wire        s_axis_tready;
  wire [15:0] m_axis_tdata;
  wire        m_axis_tvalid;

  // Etapa 6: los coeficientes ahora son puertos, no parametros - se
  // fijan aca a los mismos valores validados en la Etapa 4c (default de
  // los registros en scope_cfg.sv), para que este test siga probando lo
  // mismo que antes.
  reg signed [24:0] cfg_coeff_b0_s0 = 25'sd58743;
  reg signed [24:0] cfg_coeff_b1_s0 = 25'sd117487;
  reg signed [24:0] cfg_coeff_b2_s0 = 25'sd58743;
  reg signed [24:0] cfg_coeff_a1_s0 = -25'sd1311029;
  reg signed [24:0] cfg_coeff_a2_s0 = 25'sd526845;
  reg signed [24:0] cfg_coeff_b0_s1 = 25'sd1048576;
  reg signed [24:0] cfg_coeff_b1_s1 = -25'sd2097152;
  reg signed [24:0] cfg_coeff_b2_s1 = 25'sd1048576;
  reg signed [24:0] cfg_coeff_a1_s1 = -25'sd1984139;
  reg signed [24:0] cfg_coeff_a2_s1 = 25'sd943367;

  bandpass_filter #(.S_AXIS_DATA_BITS(16)) dut (
    .cfg_coeff_b0_s0 (cfg_coeff_b0_s0),
    .cfg_coeff_b1_s0 (cfg_coeff_b1_s0),
    .cfg_coeff_b2_s0 (cfg_coeff_b2_s0),
    .cfg_coeff_a1_s0 (cfg_coeff_a1_s0),
    .cfg_coeff_a2_s0 (cfg_coeff_a2_s0),
    .cfg_coeff_b0_s1 (cfg_coeff_b0_s1),
    .cfg_coeff_b1_s1 (cfg_coeff_b1_s1),
    .cfg_coeff_b2_s1 (cfg_coeff_b2_s1),
    .cfg_coeff_a1_s1 (cfg_coeff_a1_s1),
    .cfg_coeff_a2_s1 (cfg_coeff_a2_s1),
    .clk           (clk),
    .rst_n         (rst_n),
    .s_axis_tdata  (s_axis_tdata),
    .s_axis_tvalid (s_axis_tvalid),
    .s_axis_tready (s_axis_tready),
    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tready (1'b1)
  );

  localparam N_SAMPLES = 45877;
  reg [15:0] vec_in      [0:N_SAMPLES-1];
  reg [15:0] vec_expected[0:N_SAMPLES-1];

  integer errors = 0;
  integer checks = 0;
  integer i;
  integer max_abs_diff = 0;
  integer diff;

  // Port a Release_2026.1: se alimenta UNA muestra cada GAP ciclos (como el
  // decimador real a dec32), no una por ciclo. Alimentar una por ciclo era
  // justo lo que escondia el bug del biquad (el estado avanzaba en cada
  // ciclo, sin mirar tvalid). Un monitor compara cada salida valida contra
  // el modelo, en orden.
  localparam integer GAP = 32;
  integer fase = 1;      // 1 = vectores de la Etapa 4c, 2 = reconfiguracion
  integer k = 0;         // salidas validas vistas en la fase actual
  reg [15:0] esperado;

  always @(posedge clk) begin
    if (rst_n && m_axis_tvalid) begin
      esperado = (fase == 1) ? vec_expected[k] : (1000 + k);
      checks = checks + 1;
      if (m_axis_tdata !== esperado) begin
        errors = errors + 1;
        if (errors <= 20)
          $display("FAIL fase %0d salida %0d @ %0t: salida=%0d, se esperaba=%0d",
                   fase, k, $time, $signed(m_axis_tdata), $signed(esperado));
      end
      k = k + 1;
    end
  end

  task automatic alimentar(input [15:0] val);
    begin
      @(negedge clk);
      s_axis_tdata  = val;
      s_axis_tvalid = 1'b1;
      @(negedge clk);
      s_axis_tvalid = 1'b0;
      repeat (GAP - 1) @(negedge clk);
    end
  endtask

  initial begin
    $readmemh("../tbn/vectores/etapa4c_input.mem", vec_in);
    $readmemh("../tbn/vectores/etapa4c_expected.mem", vec_expected);

    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;

    for (i = 0; i < N_SAMPLES; i = i + 1)
      alimentar(vec_in[i]);
    repeat (2 * GAP) @(negedge clk);
    if (k !== N_SAMPLES) begin
      errors = errors + 1;
      $display("FAIL: salidas validas=%0d, se esperaban %0d", k, N_SAMPLES);
    end

    // ------------------------------------------------------------------
    // Etapa 6: reconfigurar los coeficientes EN CALIENTE (sin reset, sin
    // recompilar) a ganancia unitaria en las 2 secciones: cada salida
    // tiene que ser igual a su entrada.
    // ------------------------------------------------------------------
    cfg_coeff_b0_s0 = 25'sd1048576; cfg_coeff_b1_s0 = 0; cfg_coeff_b2_s0 = 0; cfg_coeff_a1_s0 = 0; cfg_coeff_a2_s0 = 0;
    cfg_coeff_b0_s1 = 25'sd1048576; cfg_coeff_b1_s1 = 0; cfg_coeff_b2_s1 = 0; cfg_coeff_a1_s1 = 0; cfg_coeff_a2_s1 = 0;
    repeat (10) @(negedge clk);
    fase = 2; k = 0;
    for (i = 0; i < 20; i = i + 1)
      alimentar(1000 + i);
    repeat (2 * GAP) @(negedge clk);
    if (k !== 20) begin
      errors = errors + 1;
      $display("FAIL: reconfiguracion, salidas validas=%0d, se esperaban 20", k);
    end
    $display("Chequeo de reconfiguracion en caliente (ganancia unitaria): hecho.");

    $display("--------------------------------------------------------------");
    if (errors == 0)
      $display("RESULTADO: TODOS LOS CHECKS PASARON (%0d/%0d)", checks, checks);
    else
      $display("RESULTADO: %0d CHECKS FALLARON de %0d (mostrando primeros 20)", errors, checks);
    $display("--------------------------------------------------------------");

    $finish;
  end

  initial begin
    #20_000_000;
    $display("RESULTADO: TIMEOUT - la simulacion no termino sola");
    $finish;
  end

endmodule
