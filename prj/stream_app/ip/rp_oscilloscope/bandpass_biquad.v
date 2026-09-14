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
// Sin registro AXI para cambiar coeficientes en caliente todavia - eso
// se agrega mas adelante si hace falta ajustar el filtro sin recompilar.
module bandpass_biquad #(
  parameter S_AXIS_DATA_BITS = 16,
  parameter COEFF_BITS       = 25,
  parameter FRAC_BITS        = 20,
  parameter signed [COEFF_BITS-1:0] COEFF_B0 = 0,
  parameter signed [COEFF_BITS-1:0] COEFF_B1 = 0,
  parameter signed [COEFF_BITS-1:0] COEFF_B2 = 0,
  parameter signed [COEFF_BITS-1:0] COEFF_A1 = 0,
  parameter signed [COEFF_BITS-1:0] COEFF_A2 = 0
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
  input  wire                             m_axis_tready
);

wire signed [S_AXIS_DATA_BITS-1:0] din = s_axis_tdata;

// historia: x0 = muestra actual, x1/x2 = las 2 anteriores; y1/y2 = las
// 2 salidas anteriores. x0..x2 e y1..y2 avanzan JUNTOS, un paso por
// ciclo - necesario porque el filtro tiene feedback (y1/y2 dependen de
// la salida): no se puede partir la multiplicacion-acumulacion en mas
// de un registro intermedio entre la captura de x0 y la actualizacion de
// y1, o las muestras de "x" quedan desalineadas en el tiempo respecto a
// las de "y" (probado con un diseño de 3 ciclos que rompia la Etapa 4b
// aunque pasaba la 4a, donde a1=a2=0 no dejaba ver el problema). Todo el
// producto-acumulado-saturado de abajo es COMBINACIONAL, un solo ciclo.
reg signed [S_AXIS_DATA_BITS-1:0] x0, x1, x2;
reg signed [S_AXIS_DATA_BITS-1:0] y1, y2;

always @(posedge clk)
begin
  if (~rst_n) begin
    x0 <= 'h0; x1 <= 'h0; x2 <= 'h0;
  end else begin
    x0 <= din;
    x1 <= x0;
    x2 <= x1;
  end
end

// productos: muestra (S_AXIS_DATA_BITS) * coeficiente (COEFF_BITS)
localparam integer PROD_BITS = S_AXIS_DATA_BITS + COEFF_BITS;
wire signed [PROD_BITS-1:0] prod_b0 = x0 * COEFF_B0;
wire signed [PROD_BITS-1:0] prod_b1 = x1 * COEFF_B1;
wire signed [PROD_BITS-1:0] prod_b2 = x2 * COEFF_B2;
wire signed [PROD_BITS-1:0] prod_a1 = y1 * COEFF_A1;
wire signed [PROD_BITS-1:0] prod_a2 = y2 * COEFF_A2;

// acumulador combinacional: 5 terminos de PROD_BITS, margen extra para
// no desbordar en la suma (log2(5) ~ 3 bits)
localparam integer ACC_BITS = PROD_BITS + 3;
wire signed [ACC_BITS-1:0] acc = prod_b0 + prod_b1 + prod_b2 - prod_a1 - prod_a2;

// reescalar (Qm.FRAC_BITS -> entero) y saturar al ancho de salida.
// Redondeo al mas cercano (sumar medio LSB antes de correr los bits),
// NO truncar - probado que truncar (siempre hacia -infinito) genera un
// sesgo de DC sistematico que, realimentado por los polos del filtro
// (muy cerca del circulo unidad), se acumula y satura la salida en
// corridas largas incluso con una señal de entrada perfectamente
// centrada en 0 (confirmado con una simulacion de 600k+ muestras a baja
// frecuencia). El redondeo no elimina el limit-cycle de punto fijo del
// todo (residual chico, ver README) pero evita el sesgo sistematico.
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
    m_axis_tdata <= 'h0;
    y1 <= 'h0;
    y2 <= 'h0;
  end else begin
    m_axis_tdata <= y_next;
    y2 <= y1;
    y1 <= y_next;
  end
end

// tvalid sigue el mismo pipeline de 2 ciclos que tdata (captura de x0 ->
// salida registrada), igual patron que osc_filter.v (tvalid_pipe)
reg [1:0] tvalid_pipe;
always @(posedge clk)
begin
  if (~rst_n)
    tvalid_pipe <= 'h0;
  else
    tvalid_pipe <= {tvalid_pipe[0], s_axis_tvalid};
end
assign m_axis_tvalid = tvalid_pipe[1];
assign s_axis_tready = m_axis_tready;

endmodule
