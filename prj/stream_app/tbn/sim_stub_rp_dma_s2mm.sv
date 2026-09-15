`timescale 1ns / 1ps
//
// Simulacion B (RedPitaya-FPGA): stub de rp_dma_s2mm SOLO para simulacion
// standalone de osc_top.v.
//
// Hallazgo al armar esta etapa (no estaba anticipado en el plan del
// README): rp_dma_s2mm.v se instancia DENTRO de osc_top.v (no un nivel
// arriba, en rp_oscilloscope.v, como asumia el plan original), y a su vez
// instancia fifo_axi_data, que es una IP de Xilinx (FIFO Generator, solo
// .xci/.xml, sin modelo de simulacion en texto plano). Por eso ya en esta
// etapa (no recien en la C) hace falta generar esa IP o mockear el bloque
// de DMA. Se elige mockear: el DMA hacia DDR es irrelevante para lo que
// prueba esta etapa (el contador holamundo_cnt y el resto de la cadena
// RTL de osc_top.v), y generar la IP real es justo el trabajo que le
// corresponde a la Simulacion C/D.
//
// Puertos identicos a rp_dma_s2mm.v (ver ese archivo) para que osc_top.v
// no note la diferencia. Comportamiento: nunca ocupado, siempre listo a
// aceptar datos de s_axis (asi la cadena de acquire/trigger/decimador de
// osc_top.v no queda trabada esperando backpressure de un DMA que en esta
// simulacion no existe).
//
module rp_dma_s2mm
  #(parameter AXI_ADDR_BITS   = 32,
    parameter AXI_DATA_BITS   = 64,
    parameter AXIS_DATA_BITS  = 16,
    parameter AXI_BURST_LEN   = 16)(
  input  wire                           m_axi_aclk,
  input  wire                           s_axis_aclk,
  input  wire                           aresetn,
  //
  output wire                           busy,
  output wire                           intr,
  output wire                           mode,
  //
  input  wire [31:0]                    reg_wr_data,
  input  wire                           reg_wr_we,
  //
  output wire [31:0]                    reg_ctrl,
  output wire [31:0]                    reg_sts,
  output wire [31:0]                    reg_diags,
  input  wire [31:0]                    reg_dst_addr1,
  input  wire [31:0]                    reg_dst_addr2,
  input  wire [31:0]                    reg_buf_size,
  output wire                           ctl_start_o,
  input  wire                           ctl_start_ext,
  input  wire                           use_8bit,
  //
  output wire [31:0]                    buf1_ms_cnt,
  output wire [31:0]                    buf2_ms_cnt,
  input  wire                           buf_sel_in,
  output wire                           buf_sel_out,
  //
  output wire [(AXI_ADDR_BITS-1):0]     m_axi_awaddr,
  output wire [7:0]                     m_axi_awlen,
  output wire [2:0]                     m_axi_awsize,
  output wire [1:0]                     m_axi_awburst,
  output wire [2:0]                     m_axi_awprot,
  output wire [3:0]                     m_axi_awcache,
  output wire                           m_axi_awvalid,
  input  wire                           m_axi_awready,
  output wire [AXI_DATA_BITS-1:0]       m_axi_wdata,
  output wire [(AXI_DATA_BITS/8)-1:0]   m_axi_wstrb,
  output wire                           m_axi_wlast,
  output wire                           m_axi_wvalid,
  input  wire                           m_axi_wready,
  input  wire [1:0]                     m_axi_bresp,
  input  wire                           m_axi_bvalid,
  output wire                           m_axi_bready,
  //
  input  wire [AXIS_DATA_BITS-1:0]      s_axis_tdata,
  input  wire                           s_axis_tvalid,
  output wire                           s_axis_tready,
  input  wire                           s_axis_tlast
);

  assign busy          = 1'b0;
  assign intr          = 1'b0;
  assign mode          = 1'b0;
  assign reg_ctrl      = 32'h0;
  assign reg_sts       = 32'h0;
  assign reg_diags     = 32'h0;
  assign ctl_start_o   = 1'b0;
  assign buf1_ms_cnt   = 32'h0;
  assign buf2_ms_cnt   = 32'h0;
  assign buf_sel_out   = buf_sel_in;

  assign m_axi_awaddr  = {AXI_ADDR_BITS{1'b0}};
  assign m_axi_awlen   = 8'h0;
  assign m_axi_awsize  = 3'h0;
  assign m_axi_awburst = 2'h0;
  assign m_axi_awprot  = 3'h0;
  assign m_axi_awcache = 4'h0;
  assign m_axi_awvalid = 1'b0;
  assign m_axi_wdata   = {AXI_DATA_BITS{1'b0}};
  assign m_axi_wstrb   = {(AXI_DATA_BITS/8){1'b0}};
  assign m_axi_wlast   = 1'b0;
  assign m_axi_wvalid  = 1'b0;
  assign m_axi_bready  = 1'b1;

  // Nunca aplica backpressure: la cadena de acquire de osc_top.v no debe
  // quedar esperando a un DMA que en esta simulacion no existe.
  assign s_axis_tready = 1'b1;

endmodule
