`timescale 1ns / 1ps

// Etapa 5 (RedPitaya-FPGA): acumuladores de area/kurtosis por ventana, en
// HW, sobre la señal YA filtrada (salida de bandpass_filter.v) - evita
// tener que subir la señal cruda para calcular esto en software (ver
// memoria del proyecto Sand Monitoring sec.173).
//
// Emite, una vez por ventana completa, las 3 sumas que hacen falta para
// reconstruir area y kurtosis en el host (division final en el ARM, a
// ~20 ventanas/segundo - carga insignificante):
//   sum_abs = sum(|x|)   -> area = sum_abs / fs
//   sum_x2  = sum(x^2)   -> m2 = sum_x2/N
//   sum_x4  = sum(x^4)   -> m4 = sum_x4/N ; kurtosis = m4/m2^2
//
// APROXIMACION DELIBERADA, validada antes de escribir esto (ver
// tbn/vectores/validar_etapa5_aproximacion.py): el software
// (`analisis/placa/area_kurtosis.py::_kurtosis_por_ventana`) resta la
// media EXACTA de cada ventana antes de calcular los momentos - eso
// necesita ver la ventana completa dos veces (dos pasadas), imposible
// para un acumulador de una sola pasada en streaming. Aca se asume
// media=0 (razonable post-pasabanda: ganancia ideal en DC = 0 exacto,
// confirmado en la Etapa 4c). Validado contra el archivo real de
// referencia del proyecto (8s, 160 ventanas): 100% de coincidencia de
// clasificacion (kurtosis>=6) entre la formula exacta y esta
// aproximacion, diferencia de kurtosis <0.04% en el peor caso.
//
// Anchos de los acumuladores dimensionados para el peor caso (señal a
// fondo de escala todo el tiempo) con ventanas de hasta 2^20 muestras
// (~2.6s a la fs mas baja usada en el proyecto, 32x mas grande que la
// ventana real de 50ms/dec32 - margen de sobra):
//   sum_abs: 40 bits (36 necesarios)
//   sum_x2:  52 bits (51 necesarios)
//   sum_x4:  84 bits (81 necesarios)
// Se exponen partidos en palabras de 32 bits (lo/mid/hi) porque el bus
// de registros es de 32 bits - ver scope_cfg.sv.
module area_kurtosis_accum #(
  parameter S_AXIS_DATA_BITS = 16
)(
  input  wire                             clk,
  input  wire                             rst_n,
  input  wire [S_AXIS_DATA_BITS-1:0]      s_axis_tdata,   // señal YA filtrada
  input  wire                             s_axis_tvalid,
  input  wire [31:0]                      cfg_window_samples, // N muestras por ventana (>=1)

  output reg  [39:0]                      sum_abs,   // ultima ventana completa
  output reg  [51:0]                      sum_x2,
  output reg  [83:0]                      sum_x4,
  output reg  [31:0]                      window_count // se incrementa cada ventana completa
);

wire signed [S_AXIS_DATA_BITS-1:0] x = s_axis_tdata;
wire [S_AXIS_DATA_BITS-1:0] abs_x = x[S_AXIS_DATA_BITS-1] ? (~x + 1'b1) : x;
wire [2*S_AXIS_DATA_BITS-1:0] x2 = x * x; // siempre >=0, aunque x sea signed
wire [4*S_AXIS_DATA_BITS-1:0] x4 = x2 * x2;

reg [39:0] acc_abs;
reg [51:0] acc_x2;
reg [83:0] acc_x4;
reg [31:0] sample_cnt;

wire [39:0] new_acc_abs = acc_abs + abs_x;
wire [51:0] new_acc_x2  = acc_x2  + x2;
wire [83:0] new_acc_x4  = acc_x4  + x4;
wire        window_done = (sample_cnt == (cfg_window_samples - 1));

always @(posedge clk)
begin
  if (~rst_n) begin
    acc_abs      <= 'h0;
    acc_x2       <= 'h0;
    acc_x4       <= 'h0;
    sample_cnt   <= 'h0;
    sum_abs      <= 'h0;
    sum_x2       <= 'h0;
    sum_x4       <= 'h0;
    window_count <= 'h0;
  end else if (s_axis_tvalid) begin
    if (window_done) begin
      // ventana completa: publicar la suma (incluye esta ultima muestra)
      // y arrancar la proxima ventana desde cero
      sum_abs      <= new_acc_abs;
      sum_x2       <= new_acc_x2;
      sum_x4       <= new_acc_x4;
      window_count <= window_count + 1'b1;
      acc_abs      <= 'h0;
      acc_x2       <= 'h0;
      acc_x4       <= 'h0;
      sample_cnt   <= 'h0;
    end else begin
      acc_abs    <= new_acc_abs;
      acc_x2     <= new_acc_x2;
      acc_x4     <= new_acc_x4;
      sample_cnt <= sample_cnt + 1'b1;
    end
  end
end

endmodule
