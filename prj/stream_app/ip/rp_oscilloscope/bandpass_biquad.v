`timescale 1ns / 1ps

// Pasabanda para deteccion de arena, insertado despues de calibracion y
// antes de decimar - misma señal que ve hoy el software (analisis/placa/
// en el repo Sand Monitoring).
//
// Estructura: biquad Direct Form I (b0,b1,b2,a1,a2 - 5 coeficientes,
// historia de 2 muestras de entrada y 2 de salida). Se eligio Direct
// Form I y no Direct Form II Transposed porque en punto fijo sus
// registros de historia tienen rango acotado (muestras de entrada/salida
// reales, no un estado interno que puede crecer sin límite) - ver
// "Estudio del filtro existente" en el README para el detalle completo.
//
// Etapa 4b (pasabajos de juguete): coeficientes de un pasabajos
// Butterworth orden 2 real, formula estandar RBJ Audio EQ Cookbook
// (facil de verificar contra cualquier referencia), frecuencia de corte
// normalizada f0/fs=0.05, Q=1/sqrt(2). Reemplaza los coeficientes
// triviales de la Etapa 4a (b0=1, resto 0) - esa validacion ya quedo
// documentada en el README/git, no hace falta mantenerla en paralelo.
// Los coeficientes siguen hardcodeados como localparam, sin registro AXI
// para cambiarlos en caliente - eso se agrega mas adelante si hace falta
// ajustar el filtro sin recompilar.
module bandpass_biquad #(
  parameter S_AXIS_DATA_BITS = 16
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

////////////////////////////////////////////////////////////////////////////
// Coeficientes - formato Q1.16 con signo, 18 bits (rango +-2, resolucion
// 2^-16). Etapa 4a: b0 = 1.0 exacto, resto en 0 (pasamanos matematico).
////////////////////////////////////////////////////////////////////////////
localparam integer FRAC_BITS = 16;
localparam integer COEFF_BITS = 18;
localparam signed [COEFF_BITS-1:0] COEFF_B0 = 18'sd1316;     // 0.02008337
localparam signed [COEFF_BITS-1:0] COEFF_B1 = 18'sd2632;     // 0.04016673
localparam signed [COEFF_BITS-1:0] COEFF_B2 = 18'sd1316;     // 0.02008337
localparam signed [COEFF_BITS-1:0] COEFF_A1 = -18'sd102303;  // -1.56101808
localparam signed [COEFF_BITS-1:0] COEFF_A2 = 18'sd42032;    // 0.64135154

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

// reescalar (Q1.16 -> entero) y saturar al ancho de salida
wire signed [ACC_BITS-FRAC_BITS-1:0] acc_scaled = acc >>> FRAC_BITS;
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
