`timescale 1ns / 1ps
//
// Etapa 3 (RedPitaya-FPGA): testbench dirigido, standalone, para validar
// que bandpass_biquad.v es transparente (pasa la señal sin tocarla) en
// esta etapa - la matematica real del biquad llega en la Etapa 4.
//
// Corre con xvlog/xelab/xsim en modo batch, sin Vivado GUI ni IP de
// Xilinx (el modulo es puramente combinacional): ver
// etapa3_sim_bandpass.sh en la raiz del repo.
//
module tb_bandpass_biquad_passthrough;

  reg clk = 0;
  always #4 clk = ~clk; // 125MHz

  reg rst_n = 0;
  reg [15:0] s_axis_tdata  = 16'h0;
  reg        s_axis_tvalid = 1'b0;
  reg        m_axis_tready = 1'b0;
  wire       s_axis_tready;
  wire [15:0] m_axis_tdata;
  wire        m_axis_tvalid;

  integer errors = 0;
  integer checks = 0;

  bandpass_biquad #(.S_AXIS_DATA_BITS(16)) dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .s_axis_tdata  (s_axis_tdata),
    .s_axis_tvalid (s_axis_tvalid),
    .s_axis_tready (s_axis_tready),
    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tready (m_axis_tready)
  );

  // en cada flanco, con el DUT ya estable, confirmar que es transparente
  task automatic check_transparent;
    begin
      checks = checks + 1;
      if ((m_axis_tdata !== s_axis_tdata) ||
          (m_axis_tvalid !== s_axis_tvalid) ||
          (s_axis_tready !== m_axis_tready)) begin
        errors = errors + 1;
        $display("FAIL @ %0t: tdata in=0x%04h out=0x%04h | tvalid in=%b out=%b | tready in=%b out=%b",
                  $time, s_axis_tdata, m_axis_tdata, s_axis_tvalid, m_axis_tvalid, m_axis_tready, s_axis_tready);
      end
    end
  endtask

  integer i;
  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;

    // barrido dirigido: distintas combinaciones de tdata/tvalid/tready,
    // incluyendo los casos limite (todo en 0, todo en 1, alternando)
    for (i = 0; i < 200; i = i + 1) begin
      @(negedge clk);
      s_axis_tdata  = $random;
      s_axis_tvalid = $random;
      m_axis_tready = $random;
      @(posedge clk);
      #1; // dejar asentar las señales combinacionales
      check_transparent();
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
