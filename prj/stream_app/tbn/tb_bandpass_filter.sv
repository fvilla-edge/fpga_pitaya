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

  bandpass_filter #(.S_AXIS_DATA_BITS(16)) dut (
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

  initial begin
    $readmemh("../tbn/vectores/etapa4c_input.mem", vec_in);
    $readmemh("../tbn/vectores/etapa4c_expected.mem", vec_expected);

    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;

    for (i = 0; i < N_SAMPLES + LATENCY; i = i + 1) begin
      @(negedge clk);
      if (i < N_SAMPLES) begin
        s_axis_tdata  = vec_in[i];
        s_axis_tvalid = 1'b1;
      end else begin
        s_axis_tdata  = 16'h0;
        s_axis_tvalid = 1'b0;
      end

      @(posedge clk);
      #1;

      if (i >= LATENCY) begin
        checks = checks + 1;
        if (m_axis_tdata !== vec_expected[i-LATENCY]) begin
          errors = errors + 1;
          if (errors <= 20)
            $display("FAIL muestra %0d @ %0t: salida=0x%04h (%0d), se esperaba=0x%04h (%0d)",
                      i-LATENCY, $time, m_axis_tdata, $signed(m_axis_tdata),
                      vec_expected[i-LATENCY], $signed(vec_expected[i-LATENCY]));
        end
      end
    end

    $display("--------------------------------------------------------------");
    if (errors == 0)
      $display("RESULTADO: TODOS LOS CHECKS PASARON (%0d/%0d)", checks, checks);
    else
      $display("RESULTADO: %0d CHECKS FALLARON de %0d (mostrando primeros 20)", errors, checks);
    $display("--------------------------------------------------------------");

    $finish;
  end

  initial begin
    #2_000_000;
    $display("RESULTADO: TIMEOUT - la simulacion no termino sola");
    $finish;
  end

endmodule
