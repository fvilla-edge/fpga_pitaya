`timescale 1ns / 1ps

// Una seccion de biquad Direct Form I (b0,b1,b2,a1,a2 - 5 coeficientes,
// historia de 2 muestras de entrada y 2 de salida). Se eligio Direct
// Form I y no Direct Form II Transposed porque en punto fijo sus
// registros de historia tienen rango acotado (muestras de entrada/salida
// reales, no un estado interno que puede crecer sin límite) - ver
// "Estudio del filtro existente" en el README para el detalle completo.
//
// Coeficientes como PARAMETROS (no hardcodeados) desde la Etapa 4c: el
// pasabanda real necesita 2 secciones en cascada (`butter(orden=2,
// btype="bandpass")` de scipy da 2 secciones SOS, no 1 - un pasabanda de
// orden N tiene 2N polos = N biquads), cada una con sus propios
// coeficientes - ver bandpass_filter.v, que instancia 2 de estos.
//
// Ancho de coeficientes tambien parametrizable: la Etapa 4c encontro que
// 18 bits (usado en las Etapas 4a/4b) NO alcanza para este filtro -
// midiendo contra el diseño ideal con scipy, 18 bits da hasta 9.9dB de
// error y en algunos redondeos queda INESTABLE (polos fuera del circulo
// unidad). Motivo: la banda de interes (50-400kHz) es una fraccion muy
// chica del Nyquist a 125MHz (Nyquist=62.5MHz), asi que los polos del
// filtro quedan muy pegados al circulo unidad y hace falta mucha
// precision para representarlos bien. 25 bits con 20 fraccionarios
// (COEFF_BITS=25, FRAC_BITS=20 por defecto) da <0.05dB de error contra
// el diseño ideal y encaja justo en el puerto ancho del multiplicador
// del DSP48E1 (25x18 bits).
//
// Etapa 6 (RedPitaya-FPGA): coeficientes configurables por registro AXI
// en caliente, sin recompilar - reemplaza los parametros de compilacion
// de la Etapa 4c (ahora son puertos de entrada, wires). El default de
// esos registros (en scope_cfg.sv) sigue siendo el pasabanda real
// validado en la Etapa 4c, así que sin tocar nada desde software el
// comportamiento es identico a antes - esto solo agrega la posibilidad
// de cambiarlo. Motivado por una limitacion real encontrada en la 4c: el
// filtro tenia los coeficientes fijos para decimacion 32 unicamente:
// ahora el host puede recalcular y cargar coeficientes nuevos si usa
// decimacion 64 (u otra banda), sin recompilar el bitstream.
module bandpass_biquad #(
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
  output reg  [S_AXIS_DATA_BITS-1:0]      m_axis_tdata,
  output wire                             m_axis_tvalid,
  input  wire                             m_axis_tready,
  // Coeficientes (Etapa 6: configurables, ver arriba)
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_b0,
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_b1,
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_b2,
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_a1,
  input  wire signed [COEFF_BITS-1:0]     cfg_coeff_a2
);

wire signed [S_AXIS_DATA_BITS-1:0] din = s_axis_tdata;

// Port a Release_2026.1 — DOS arreglos:
//
// 1) BUG REAL: antes x0..x2 / y1..y2 avanzaban en CADA ciclo de clk, sin
//    mirar s_axis_tvalid. Los testbenches daban una muestra por ciclo y no
//    lo veian, pero en la placa el decimador entrega una muestra cada
//    cfg_dec_factor ciclos (32 a dec32) y la mantiene quieta: el filtro
//    iteraba 32 veces por muestra, o sea era OTRO filtro (coeficientes de
//    fs=3906250Hz corriendo a 125MHz, banda corrida x32). Ahora el estado
//    avanza solo con una muestra valida.
//
// 2) TIMING: el producto-acumulado-saturado combinacional de un ciclo no
//    entraba en 8ns (WNS -9.4ns con Vivado 2025.1). Como entre muestras
//    validas hay >=32 ciclos, se parte en 4 etapas registradas y la
//    recursion (y1/y2) se cierra al final, antes de la muestra siguiente.
//    Las cuentas son exactamente las mismas (bit-exacto con el modelo).
//    REQUISITO: al menos 5 ciclos de clk entre muestras validas
//    (decimacion >= 5); con muestras mas seguidas se pisarian las etapas.
//
//    etapa 0 (s_axis_tvalid): x2<=x1, x1<=x0, x0<=din
//    etapa 1: los 5 productos
//    etapa 2: suma
//    etapa 3: redondeo + escalado + saturacion -> y1/y2 y la salida
reg signed [S_AXIS_DATA_BITS-1:0] x0, x1, x2;
reg signed [S_AXIS_DATA_BITS-1:0] y1, y2;
reg [3:0] v;  // v[k] = la etapa k tiene una muestra en curso

localparam integer PROD_BITS = S_AXIS_DATA_BITS + COEFF_BITS;
localparam integer ACC_BITS  = PROD_BITS + 3;
reg signed [PROD_BITS-1:0] p_b0, p_b1, p_b2, p_a1, p_a2;
reg signed [ACC_BITS-1:0]  acc;

localparam signed [ACC_BITS-1:0] ROUND_BIAS = {{(ACC_BITS-FRAC_BITS){1'b0}}, 1'b1, {(FRAC_BITS-1){1'b0}}};
wire signed [ACC_BITS-FRAC_BITS-1:0] acc_scaled = (acc + ROUND_BIAS) >>> FRAC_BITS;
localparam signed [S_AXIS_DATA_BITS-1:0] SAT_MAX = {1'b0, {(S_AXIS_DATA_BITS-1){1'b1}}};
localparam signed [S_AXIS_DATA_BITS-1:0] SAT_MIN = {1'b1, {(S_AXIS_DATA_BITS-1){1'b0}}};
wire signed [S_AXIS_DATA_BITS-1:0] y_next =
  (acc_scaled > $signed(SAT_MAX)) ? SAT_MAX :
  (acc_scaled < $signed(SAT_MIN)) ? SAT_MIN :
  acc_scaled[S_AXIS_DATA_BITS-1:0];

always @(posedge clk)
begin
  if (~rst_n) begin
    x0 <= 'h0; x1 <= 'h0; x2 <= 'h0;
    y1 <= 'h0; y2 <= 'h0;
    p_b0 <= 'h0; p_b1 <= 'h0; p_b2 <= 'h0; p_a1 <= 'h0; p_a2 <= 'h0;
    acc <= 'h0;
    m_axis_tdata <= 'h0;
    v <= 'h0;
  end else begin
    v <= {v[2:0], s_axis_tvalid};
    // etapa 0
    if (s_axis_tvalid) begin
      x0 <= din;
      x1 <= x0;
      x2 <= x1;
    end
    // etapa 1
    if (v[0]) begin
      p_b0 <= x0 * cfg_coeff_b0;
      p_b1 <= x1 * cfg_coeff_b1;
      p_b2 <= x2 * cfg_coeff_b2;
      p_a1 <= y1 * cfg_coeff_a1;
      p_a2 <= y2 * cfg_coeff_a2;
    end
    // etapa 2
    if (v[1])
      acc <= p_b0 + p_b1 + p_b2 - p_a1 - p_a2;
    // etapa 3
    if (v[2]) begin
      m_axis_tdata <= y_next;
      y2 <= y1;
      y1 <= y_next;
    end
  end
end

assign m_axis_tvalid = v[3];
assign s_axis_tready = m_axis_tready;

endmodule
