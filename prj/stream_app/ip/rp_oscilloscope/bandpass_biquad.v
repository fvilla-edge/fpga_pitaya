`timescale 1ns / 1ps

// Etapa 3 (RedPitaya-FPGA): pasabanda para deteccion de arena, insertado
// despues de calibracion y antes de decimar - misma señal que ve hoy el
// software (analisis/placa/ en el repo Sand Monitoring).
//
// Por ahora es SOLO un "pasamanos": pasa la señal sin tocarla, cero
// latencia agregada (combinacional puro, sin registros). El objetivo de
// esta etapa es validar que el bloque encaja en el lugar correcto del
// pipeline sin romper el flujo de datos - la matematica real del biquad
// (Direct Form I, ver README) se agrega en la Etapa 4, en el mismo lugar
// donde hoy solo hay wires.
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
  output wire [S_AXIS_DATA_BITS-1:0]      m_axis_tdata,
  output wire                             m_axis_tvalid,
  input  wire                             m_axis_tready
);

assign m_axis_tdata  = s_axis_tdata;
assign m_axis_tvalid = s_axis_tvalid;
assign s_axis_tready = m_axis_tready;

endmodule
