`timescale 1ns / 1ps
//
// Etapa 4b (RedPitaya-FPGA): testbench dirigido, standalone, para validar
// bandpass_biquad.v con coeficientes NO triviales (pasabajos de juguete,
// formula RBJ Audio EQ Cookbook, f0/fs=0.05, Q=1/sqrt(2)).
//
// Vectores golden generados con un modelo Python que replica EXACTAMENTE
// la misma aritmetica de punto fijo del RTL (mismos coeficientes
// cuantizados Q1.16, mismo corrimiento aritmetico, misma saturacion a 16
// bits) - no es una comparacion contra el filtro ideal en punto flotante,
// es una comparacion bit exacta contra "lo que este punto fijo deberia
// dar". Ver tbn/vectores/etapa4b_input.mem y etapa4b_expected.mem.
//
// Corre con xvlog/xelab/xsim en modo batch, sin GUI: ver
// etapa4b_sim_bandpass.sh en la raiz del repo.
//
module tb_bandpass_biquad_lowpass;

  localparam LATENCY = 1;
  localparam N_SAMPLES = 200;

  reg clk = 0;
  always #4 clk = ~clk; // 125MHz

  reg rst_n = 0;
  reg  [15:0] s_axis_tdata  = 16'h0;
  reg         s_axis_tvalid = 1'b0;
  wire        s_axis_tready;
  wire [15:0] m_axis_tdata;
  wire        m_axis_tvalid;

  bandpass_biquad #(.S_AXIS_DATA_BITS(16)) dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .s_axis_tdata  (s_axis_tdata),
    .s_axis_tvalid (s_axis_tvalid),
    .s_axis_tready (s_axis_tready),
    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tready (1'b1)
  );

  reg [15:0] vec_in      [0:N_SAMPLES-1];
  reg [15:0] vec_expected[0:N_SAMPLES-1];

  integer errors = 0;
  integer checks = 0;
  integer i;

  initial begin
    $readmemh("../tbn/vectores/etapa4b_input.mem", vec_in);
    $readmemh("../tbn/vectores/etapa4b_expected.mem", vec_expected);

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
      $display("RESULTADO: %0d CHECKS FALLARON de %0d", errors, checks);
    $display("--------------------------------------------------------------");

    $finish;
  end

  initial begin
    #100000;
    $display("RESULTADO: TIMEOUT - la simulacion no termino sola");
    $finish;
  end

endmodule
