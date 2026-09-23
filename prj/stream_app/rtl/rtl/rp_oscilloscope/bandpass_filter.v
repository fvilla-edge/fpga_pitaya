`timescale 1ns / 1ps

// Pasabanda real para deteccion de arena, 50-400kHz, Butterworth orden 2
// - insertado DESPUES de decimar (ver README, seccion "Estudio del
// filtro existente" y la nota junto a la instanciacion de este modulo en
// osc_top.v: se probo antes de decimar primero, a 125MHz los polos
// quedaban pegados al circulo unidad y el punto fijo entraba en un
// "limit cycle" real - no decaia a cero ni en silencio).
//
// Un pasabanda Butterworth de orden N tiene 2N polos = N secciones SOS
// (confirmado con scipy: butter(2, ..., btype="bandpass", output="sos")
// da 2 filas, no 1) - por eso este modulo cascadea 2 bandpass_biquad,
// no uno solo.
//
// Etapa 6: los coeficientes de las 2 secciones son puertos de entrada
// (antes, en la Etapa 4c, eran parametros hardcodeados) - el valor por
// defecto de esos registros (en scope_cfg.sv) es el pasabanda real ya
// validado (fs=3906250Hz, ADC a 125MHz decimado por 32), así que sin
// tocar nada desde software el comportamiento es identico a la Etapa
// 4c. Esto resuelve la limitacion que habia quedado documentada ahi: el
// filtro tenia los coeficientes fijos para decimacion 32 unicamente - el
// host ahora puede recalcular y cargar coeficientes nuevos (con scipy,
// mismo metodo que tbn/vectores/generar_etapa4c.py) para decimacion 64 u
// otra banda, sin recompilar el bitstream.
module bandpass_filter #(
  parameter S_AXIS_DATA_BITS = 16,
  parameter COEFF_BITS       = 25,
  parameter FRAC_BITS        = 20
)(
  input  wire                             clk,
  input  wire                             rst_n,
  // Slave AXI-S
  input  wire [S_AXIS_DATA_BITS-1:0]      s_axis_tdata,
  input  wire                             s_axis_tvalid,
  output wire                             s_axis_tready,
  // Master AXI-S
  output wire [S_AXIS_DATA_BITS-1:0]      m_axis_tdata,
  output wire                             m_axis_tvalid,
  input  wire                             m_axis_tready,
  // Coeficientes, seccion 0 (scipy sos[0])
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_b0_s0,
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_b1_s0,
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_b2_s0,
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_a1_s0,
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_a2_s0,
  // Coeficientes, seccion 1 (scipy sos[1])
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_b0_s1,
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_b1_s1,
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_b2_s1,
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_a1_s1,
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_a2_s1
);

wire [S_AXIS_DATA_BITS-1:0] mid_tdata;
wire                        mid_tvalid;
wire                        mid_tready;

bandpass_biquad #(
  .S_AXIS_DATA_BITS (S_AXIS_DATA_BITS),
  .COEFF_BITS       (COEFF_BITS),
  .FRAC_BITS        (FRAC_BITS)
) U_seccion0 (
  .clk           (clk),
  .rst_n         (rst_n),
  .s_axis_tdata  (s_axis_tdata),
  .s_axis_tvalid (s_axis_tvalid),
  .s_axis_tready (s_axis_tready),
  .m_axis_tdata  (mid_tdata),
  .m_axis_tvalid (mid_tvalid),
  .m_axis_tready (mid_tready),
  .cfg_coeff_b0  (cfg_coeff_b0_s0),
  .cfg_coeff_b1  (cfg_coeff_b1_s0),
  .cfg_coeff_b2  (cfg_coeff_b2_s0),
  .cfg_coeff_a1  (cfg_coeff_a1_s0),
  .cfg_coeff_a2  (cfg_coeff_a2_s0)
);

bandpass_biquad #(
  .S_AXIS_DATA_BITS (S_AXIS_DATA_BITS),
  .COEFF_BITS       (COEFF_BITS),
  .FRAC_BITS        (FRAC_BITS)
) U_seccion1 (
  .clk           (clk),
  .rst_n         (rst_n),
  .s_axis_tdata  (mid_tdata),
  .s_axis_tvalid (mid_tvalid),
  .s_axis_tready (mid_tready),
  .m_axis_tdata  (m_axis_tdata),
  .m_axis_tvalid (m_axis_tvalid),
  .m_axis_tready (m_axis_tready),
  .cfg_coeff_b0  (cfg_coeff_b0_s1),
  .cfg_coeff_b1  (cfg_coeff_b1_s1),
  .cfg_coeff_b2  (cfg_coeff_b2_s1),
  .cfg_coeff_a1  (cfg_coeff_a1_s1),
  .cfg_coeff_a2  (cfg_coeff_a2_s1)
);

endmodule
