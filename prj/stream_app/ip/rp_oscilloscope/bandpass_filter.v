`timescale 1ns / 1ps

// Etapa 4c (RedPitaya-FPGA): pasabanda real para deteccion de arena,
// 50-400kHz, Butterworth orden 2 - insertado DESPUES de decimar (ver
// README, seccion "Estudio del filtro existente" y la nota junto a la
// instanciacion de este modulo en osc_top.v: se probo antes de decimar
// primero, a 125MHz los polos quedaban pegados al circulo unidad y el
// punto fijo entraba en un "limit cycle" real - no decaia a cero ni en
// silencio).
//
// Un pasabanda Butterworth de orden N tiene 2N polos = N secciones SOS
// (confirmado con scipy: butter(2, ..., btype="bandpass", output="sos")
// da 2 filas, no 1) - por eso este modulo cascadea 2 bandpass_biquad,
// no uno solo. Coeficientes calculados para fs=3906250Hz (ADC a 125MHz
// decimado por 32) - misma banda y orden que el software
// (`analisis/placa/` en Sand Monitoring), pero coeficientes propios
// calculados para esta implementacion, no copiados: el software filtra
// la señal ya decimada leyendo el fs real de cada captura desde
// session_..._info.json (soporta decimacion 32 o 64 sin cambios), pero
// este filtro en HW tiene los coeficientes fijos en el bitstream, así
// que asume decimacion 32 - si se usa decimacion 64 con este bitstream
// el filtro queda corrido de banda (limitacion conocida, sin resolver).
//
// Generados con scipy (band=(50e3,400e3), fs=3906250, orden=2),
// cuantizados a Q<FRAC_BITS> con signo en COEFF_BITS bits (25 bits, 20
// fraccionarios - ver bandpass_biquad.v para el porque de este ancho).
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
  input  wire                             m_axis_tready
);

wire [S_AXIS_DATA_BITS-1:0] mid_tdata;
wire                        mid_tvalid;
wire                        mid_tready;

// seccion 0 (scipy sos[0], fs=3906250Hz)
bandpass_biquad #(
  .S_AXIS_DATA_BITS (S_AXIS_DATA_BITS),
  .COEFF_BITS       (COEFF_BITS),
  .FRAC_BITS        (FRAC_BITS),
  .COEFF_B0         (25'sd58743),
  .COEFF_B1         (25'sd117487),
  .COEFF_B2         (25'sd58743),
  .COEFF_A1         (-25'sd1311029),
  .COEFF_A2         (25'sd526845)
) U_seccion0 (
  .clk           (clk),
  .rst_n         (rst_n),
  .s_axis_tdata  (s_axis_tdata),
  .s_axis_tvalid (s_axis_tvalid),
  .s_axis_tready (s_axis_tready),
  .m_axis_tdata  (mid_tdata),
  .m_axis_tvalid (mid_tvalid),
  .m_axis_tready (mid_tready)
);

// seccion 1 (scipy sos[1], fs=3906250Hz)
bandpass_biquad #(
  .S_AXIS_DATA_BITS (S_AXIS_DATA_BITS),
  .COEFF_BITS       (COEFF_BITS),
  .FRAC_BITS        (FRAC_BITS),
  .COEFF_B0         (25'sd1048576),
  .COEFF_B1         (-25'sd2097152),
  .COEFF_B2         (25'sd1048576),
  .COEFF_A1         (-25'sd1984139),
  .COEFF_A2         (25'sd943367)
) U_seccion1 (
  .clk           (clk),
  .rst_n         (rst_n),
  .s_axis_tdata  (mid_tdata),
  .s_axis_tvalid (mid_tvalid),
  .s_axis_tready (mid_tready),
  .m_axis_tdata  (m_axis_tdata),
  .m_axis_tvalid (m_axis_tvalid),
  .m_axis_tready (m_axis_tready)
);

endmodule
