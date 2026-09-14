// (c) Copyright 1995-2026 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: redpitaya.com:user:rp_oscilloscope:1.16
// IP Revision: 47

(* X_CORE_INFO = "rp_oscilloscope,Vivado 2020.1" *)
(* CHECK_LICENSE_TYPE = "system_rp_oscilloscope_0,rp_oscilloscope,{}" *)
(* IP_DEFINITION_SOURCE = "package_project" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module system_rp_oscilloscope_0 (
  clk,
  rst_n,
  intr,
  adc_data_ch1,
  adc_data_ch2,
  adc_data_ch3,
  adc_data_ch4,
  event_ip_trig,
  event_ip_stop,
  event_ip_start,
  event_ip_reset,
  trig_ip,
  trig_out,
  clksel_o,
  daisy_slave_i,
  osc1_event_op,
  osc1_trig_op,
  osc2_event_op,
  osc2_trig_op,
  osc3_event_op,
  osc3_trig_op,
  osc4_event_op,
  osc4_trig_op,
  loopback_sel,
  s_axi_reg_aclk,
  s_axi_reg_aresetn,
  s_axi_reg_awaddr,
  s_axi_reg_awprot,
  s_axi_reg_awvalid,
  s_axi_reg_awready,
  s_axi_reg_wdata,
  s_axi_reg_wstrb,
  s_axi_reg_wvalid,
  s_axi_reg_wready,
  s_axi_reg_wlast,
  s_axi_reg_bresp,
  s_axi_reg_bvalid,
  s_axi_reg_bready,
  s_axi_reg_araddr,
  s_axi_reg_arprot,
  s_axi_reg_arvalid,
  s_axi_reg_arready,
  s_axi_reg_rdata,
  s_axi_reg_rresp,
  s_axi_reg_rvalid,
  s_axi_reg_rready,
  s_axi_reg_rlast,
  s_axi_reg_awid,
  s_axi_reg_arid,
  s_axi_reg_wid,
  s_axi_reg_rid,
  s_axi_reg_bid,
  m_axi_osc1_aclk,
  m_axi_osc1_aresetn,
  m_axi_osc1_awaddr,
  m_axi_osc1_awlen,
  m_axi_osc1_awsize,
  m_axi_osc1_awburst,
  m_axi_osc1_awprot,
  m_axi_osc1_awcache,
  m_axi_osc1_awvalid,
  m_axi_osc1_awready,
  m_axi_osc1_wdata,
  m_axi_osc1_wstrb,
  m_axi_osc1_wlast,
  m_axi_osc1_wvalid,
  m_axi_osc1_wready,
  m_axi_osc1_bresp,
  m_axi_osc1_bvalid,
  m_axi_osc1_bready,
  m_axi_osc2_aclk,
  m_axi_osc2_aresetn,
  m_axi_osc2_awaddr,
  m_axi_osc2_awlen,
  m_axi_osc2_awsize,
  m_axi_osc2_awburst,
  m_axi_osc2_awprot,
  m_axi_osc2_awcache,
  m_axi_osc2_awvalid,
  m_axi_osc2_awready,
  m_axi_osc2_wdata,
  m_axi_osc2_wstrb,
  m_axi_osc2_wlast,
  m_axi_osc2_wvalid,
  m_axi_osc2_wready,
  m_axi_osc2_bresp,
  m_axi_osc2_bvalid,
  m_axi_osc2_bready,
  m_axi_osc3_aclk,
  m_axi_osc3_aresetn,
  m_axi_osc3_awaddr,
  m_axi_osc3_awlen,
  m_axi_osc3_awsize,
  m_axi_osc3_awburst,
  m_axi_osc3_awprot,
  m_axi_osc3_awcache,
  m_axi_osc3_awvalid,
  m_axi_osc3_awready,
  m_axi_osc3_wdata,
  m_axi_osc3_wstrb,
  m_axi_osc3_wlast,
  m_axi_osc3_wvalid,
  m_axi_osc3_wready,
  m_axi_osc3_bresp,
  m_axi_osc3_bvalid,
  m_axi_osc3_bready,
  m_axi_osc4_aclk,
  m_axi_osc4_aresetn,
  m_axi_osc4_awaddr,
  m_axi_osc4_awlen,
  m_axi_osc4_awsize,
  m_axi_osc4_awburst,
  m_axi_osc4_awprot,
  m_axi_osc4_awcache,
  m_axi_osc4_awvalid,
  m_axi_osc4_awready,
  m_axi_osc4_wdata,
  m_axi_osc4_wstrb,
  m_axi_osc4_wlast,
  m_axi_osc4_wvalid,
  m_axi_osc4_wready,
  m_axi_osc4_bresp,
  m_axi_osc4_bvalid,
  m_axi_osc4_bready
);

(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME clk, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
input wire clk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rst_n, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_n RST" *)
input wire rst_n;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME intr, SENSITIVITY LEVEL_HIGH, PortWidth 1" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 intr INTERRUPT" *)
output wire intr;
input wire [13 : 0] adc_data_ch1;
input wire [13 : 0] adc_data_ch2;
input wire [13 : 0] adc_data_ch3;
input wire [13 : 0] adc_data_ch4;
input wire [4 : 0] event_ip_trig;
input wire [4 : 0] event_ip_stop;
input wire [4 : 0] event_ip_start;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME event_ip_reset, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 event_ip_reset RST" *)
input wire [4 : 0] event_ip_reset;
input wire [5 : 0] trig_ip;
output wire trig_out;
output wire clksel_o;
input wire daisy_slave_i;
output wire [3 : 0] osc1_event_op;
output wire osc1_trig_op;
output wire [3 : 0] osc2_event_op;
output wire osc2_trig_op;
output wire [3 : 0] osc3_event_op;
output wire osc3_trig_op;
output wire [3 : 0] osc4_event_op;
output wire osc4_trig_op;
output wire [7 : 0] loopback_sel;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_reg_aclk, ASSOCIATED_BUSIF s_axi_reg, ASSOCIATED_RESET s_axi_reg_aresetn, FREQ_HZ 50000000, FREQ_TOLERANCE_HZ 0, PHASE 0.000, CLK_DOMAIN system_processing_system7_0_0_FCLK_CLK2, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_reg_aclk CLK" *)
input wire s_axi_reg_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_reg_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_reg_aresetn RST" *)
input wire s_axi_reg_aresetn;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg AWADDR" *)
input wire [19 : 0] s_axi_reg_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg AWPROT" *)
input wire [2 : 0] s_axi_reg_awprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg AWVALID" *)
input wire s_axi_reg_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg AWREADY" *)
output wire s_axi_reg_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg WDATA" *)
input wire [31 : 0] s_axi_reg_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg WSTRB" *)
input wire [3 : 0] s_axi_reg_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg WVALID" *)
input wire s_axi_reg_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg WREADY" *)
output wire s_axi_reg_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg WLAST" *)
input wire s_axi_reg_wlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg BRESP" *)
output wire [1 : 0] s_axi_reg_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg BVALID" *)
output wire s_axi_reg_bvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg BREADY" *)
input wire s_axi_reg_bready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg ARADDR" *)
input wire [19 : 0] s_axi_reg_araddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg ARPROT" *)
input wire [2 : 0] s_axi_reg_arprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg ARVALID" *)
input wire s_axi_reg_arvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg ARREADY" *)
output wire s_axi_reg_arready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg RDATA" *)
output wire [31 : 0] s_axi_reg_rdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg RRESP" *)
output wire [1 : 0] s_axi_reg_rresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg RVALID" *)
output wire s_axi_reg_rvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg RREADY" *)
input wire s_axi_reg_rready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg RLAST" *)
output wire s_axi_reg_rlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg AWID" *)
input wire [11 : 0] s_axi_reg_awid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg ARID" *)
input wire [11 : 0] s_axi_reg_arid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg WID" *)
input wire [11 : 0] s_axi_reg_wid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg RID" *)
output wire [11 : 0] s_axi_reg_rid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_reg, PROTOCOL AXI3, DATA_WIDTH 32, FREQ_HZ 50000000, ID_WIDTH 12, ADDR_WIDTH 20, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 16, PHASE 0.000, CLK_DOMAIN system_processing_system7_0_0_FCLK_CLK2, NUM_READ_THREADS\
 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg BID" *)
output wire [11 : 0] s_axi_reg_bid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_osc1_aclk, ASSOCIATED_BUSIF m_axi_osc1, ASSOCIATED_RESET m_axi_osc1_aresetn, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 m_axi_osc1_aclk CLK" *)
input wire m_axi_osc1_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_osc1_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 m_axi_osc1_aresetn RST" *)
input wire m_axi_osc1_aresetn;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 AWADDR" *)
output wire [31 : 0] m_axi_osc1_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 AWLEN" *)
output wire [7 : 0] m_axi_osc1_awlen;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 AWSIZE" *)
output wire [2 : 0] m_axi_osc1_awsize;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 AWBURST" *)
output wire [1 : 0] m_axi_osc1_awburst;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 AWPROT" *)
output wire [2 : 0] m_axi_osc1_awprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 AWCACHE" *)
output wire [3 : 0] m_axi_osc1_awcache;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 AWVALID" *)
output wire m_axi_osc1_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 AWREADY" *)
input wire m_axi_osc1_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 WDATA" *)
output wire [63 : 0] m_axi_osc1_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 WSTRB" *)
output wire [7 : 0] m_axi_osc1_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 WLAST" *)
output wire m_axi_osc1_wlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 WVALID" *)
output wire m_axi_osc1_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 WREADY" *)
input wire m_axi_osc1_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 BRESP" *)
input wire [1 : 0] m_axi_osc1_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 BVALID" *)
input wire m_axi_osc1_bvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_osc1, DATA_WIDTH 64, PROTOCOL AXI4, FREQ_HZ 125000000, ID_WIDTH 0, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE WRITE_ONLY, HAS_BURST 1, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 0, SUPPORTS_NARROW_BURST 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 256, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, NUM_READ_THREADS 1, NUM_WRITE_THREADS \
1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc1 BREADY" *)
output wire m_axi_osc1_bready;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_osc2_aclk, ASSOCIATED_BUSIF m_axi_osc2, ASSOCIATED_RESET m_axi_osc2_aresetn, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 m_axi_osc2_aclk CLK" *)
input wire m_axi_osc2_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_osc2_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 m_axi_osc2_aresetn RST" *)
input wire m_axi_osc2_aresetn;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 AWADDR" *)
output wire [31 : 0] m_axi_osc2_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 AWLEN" *)
output wire [7 : 0] m_axi_osc2_awlen;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 AWSIZE" *)
output wire [2 : 0] m_axi_osc2_awsize;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 AWBURST" *)
output wire [1 : 0] m_axi_osc2_awburst;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 AWPROT" *)
output wire [2 : 0] m_axi_osc2_awprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 AWCACHE" *)
output wire [3 : 0] m_axi_osc2_awcache;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 AWVALID" *)
output wire m_axi_osc2_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 AWREADY" *)
input wire m_axi_osc2_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 WDATA" *)
output wire [63 : 0] m_axi_osc2_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 WSTRB" *)
output wire [7 : 0] m_axi_osc2_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 WLAST" *)
output wire m_axi_osc2_wlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 WVALID" *)
output wire m_axi_osc2_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 WREADY" *)
input wire m_axi_osc2_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 BRESP" *)
input wire [1 : 0] m_axi_osc2_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 BVALID" *)
input wire m_axi_osc2_bvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_osc2, DATA_WIDTH 64, PROTOCOL AXI4, FREQ_HZ 125000000, ID_WIDTH 0, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE WRITE_ONLY, HAS_BURST 1, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 0, SUPPORTS_NARROW_BURST 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 256, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, NUM_READ_THREADS 1, NUM_WRITE_THREADS \
1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc2 BREADY" *)
output wire m_axi_osc2_bready;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_osc3_aclk, ASSOCIATED_BUSIF m_axi_osc3, ASSOCIATED_RESET m_axi_osc3_aresetn, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 m_axi_osc3_aclk CLK" *)
input wire m_axi_osc3_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_osc3_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 m_axi_osc3_aresetn RST" *)
input wire m_axi_osc3_aresetn;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 AWADDR" *)
output wire [31 : 0] m_axi_osc3_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 AWLEN" *)
output wire [7 : 0] m_axi_osc3_awlen;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 AWSIZE" *)
output wire [2 : 0] m_axi_osc3_awsize;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 AWBURST" *)
output wire [1 : 0] m_axi_osc3_awburst;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 AWPROT" *)
output wire [2 : 0] m_axi_osc3_awprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 AWCACHE" *)
output wire [3 : 0] m_axi_osc3_awcache;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 AWVALID" *)
output wire m_axi_osc3_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 AWREADY" *)
input wire m_axi_osc3_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 WDATA" *)
output wire [63 : 0] m_axi_osc3_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 WSTRB" *)
output wire [7 : 0] m_axi_osc3_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 WLAST" *)
output wire m_axi_osc3_wlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 WVALID" *)
output wire m_axi_osc3_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 WREADY" *)
input wire m_axi_osc3_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 BRESP" *)
input wire [1 : 0] m_axi_osc3_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 BVALID" *)
input wire m_axi_osc3_bvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_osc3, DATA_WIDTH 64, PROTOCOL AXI4, FREQ_HZ 125000000, ID_WIDTH 0, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE WRITE_ONLY, HAS_BURST 1, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 0, SUPPORTS_NARROW_BURST 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 256, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, NUM_READ_THREADS 1, NUM_WRITE_THREADS \
1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc3 BREADY" *)
output wire m_axi_osc3_bready;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_osc4_aclk, ASSOCIATED_BUSIF m_axi_osc4, ASSOCIATED_RESET m_axi_osc4_aresetn, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 m_axi_osc4_aclk CLK" *)
input wire m_axi_osc4_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_osc4_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 m_axi_osc4_aresetn RST" *)
input wire m_axi_osc4_aresetn;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 AWADDR" *)
output wire [31 : 0] m_axi_osc4_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 AWLEN" *)
output wire [7 : 0] m_axi_osc4_awlen;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 AWSIZE" *)
output wire [2 : 0] m_axi_osc4_awsize;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 AWBURST" *)
output wire [1 : 0] m_axi_osc4_awburst;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 AWPROT" *)
output wire [2 : 0] m_axi_osc4_awprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 AWCACHE" *)
output wire [3 : 0] m_axi_osc4_awcache;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 AWVALID" *)
output wire m_axi_osc4_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 AWREADY" *)
input wire m_axi_osc4_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 WDATA" *)
output wire [63 : 0] m_axi_osc4_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 WSTRB" *)
output wire [7 : 0] m_axi_osc4_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 WLAST" *)
output wire m_axi_osc4_wlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 WVALID" *)
output wire m_axi_osc4_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 WREADY" *)
input wire m_axi_osc4_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 BRESP" *)
input wire [1 : 0] m_axi_osc4_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 BVALID" *)
input wire m_axi_osc4_bvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_osc4, DATA_WIDTH 64, PROTOCOL AXI4, FREQ_HZ 125000000, ID_WIDTH 0, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE WRITE_ONLY, HAS_BURST 1, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 0, SUPPORTS_NARROW_BURST 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 256, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, NUM_READ_THREADS 1, NUM_WRITE_THREADS \
1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_osc4 BREADY" *)
output wire m_axi_osc4_bready;

  rp_oscilloscope #(
    .S_AXI_REG_ADDR_BITS(20),
    .M_AXI_OSC1_ADDR_BITS(32),
    .M_AXI_OSC1_DATA_BITS(64),
    .M_AXI_OSC2_ADDR_BITS(32),
    .M_AXI_OSC2_DATA_BITS(64),
    .M_AXI_OSC3_ADDR_BITS(32),
    .M_AXI_OSC3_DATA_BITS(64),
    .M_AXI_OSC4_ADDR_BITS(32),
    .M_AXI_OSC4_DATA_BITS(64),
    .ADC_DATA_BITS(14),
    .EVENT_SRC_NUM(5),
    .TRIG_SRC_NUM(6),
    .NUM_CHANNELS(2),
    .ID_WIDTHS(12)
  ) inst (
    .clk(clk),
    .rst_n(rst_n),
    .intr(intr),
    .adc_data_ch1(adc_data_ch1),
    .adc_data_ch2(adc_data_ch2),
    .adc_data_ch3(adc_data_ch3),
    .adc_data_ch4(adc_data_ch4),
    .event_ip_trig(event_ip_trig),
    .event_ip_stop(event_ip_stop),
    .event_ip_start(event_ip_start),
    .event_ip_reset(event_ip_reset),
    .trig_ip(trig_ip),
    .trig_out(trig_out),
    .clksel_o(clksel_o),
    .daisy_slave_i(daisy_slave_i),
    .osc1_event_op(osc1_event_op),
    .osc1_trig_op(osc1_trig_op),
    .osc2_event_op(osc2_event_op),
    .osc2_trig_op(osc2_trig_op),
    .osc3_event_op(osc3_event_op),
    .osc3_trig_op(osc3_trig_op),
    .osc4_event_op(osc4_event_op),
    .osc4_trig_op(osc4_trig_op),
    .loopback_sel(loopback_sel),
    .s_axi_reg_aclk(s_axi_reg_aclk),
    .s_axi_reg_aresetn(s_axi_reg_aresetn),
    .s_axi_reg_awaddr(s_axi_reg_awaddr),
    .s_axi_reg_awprot(s_axi_reg_awprot),
    .s_axi_reg_awvalid(s_axi_reg_awvalid),
    .s_axi_reg_awready(s_axi_reg_awready),
    .s_axi_reg_wdata(s_axi_reg_wdata),
    .s_axi_reg_wstrb(s_axi_reg_wstrb),
    .s_axi_reg_wvalid(s_axi_reg_wvalid),
    .s_axi_reg_wready(s_axi_reg_wready),
    .s_axi_reg_wlast(s_axi_reg_wlast),
    .s_axi_reg_bresp(s_axi_reg_bresp),
    .s_axi_reg_bvalid(s_axi_reg_bvalid),
    .s_axi_reg_bready(s_axi_reg_bready),
    .s_axi_reg_araddr(s_axi_reg_araddr),
    .s_axi_reg_arprot(s_axi_reg_arprot),
    .s_axi_reg_arvalid(s_axi_reg_arvalid),
    .s_axi_reg_arready(s_axi_reg_arready),
    .s_axi_reg_rdata(s_axi_reg_rdata),
    .s_axi_reg_rresp(s_axi_reg_rresp),
    .s_axi_reg_rvalid(s_axi_reg_rvalid),
    .s_axi_reg_rready(s_axi_reg_rready),
    .s_axi_reg_rlast(s_axi_reg_rlast),
    .s_axi_reg_awid(s_axi_reg_awid),
    .s_axi_reg_arid(s_axi_reg_arid),
    .s_axi_reg_wid(s_axi_reg_wid),
    .s_axi_reg_rid(s_axi_reg_rid),
    .s_axi_reg_bid(s_axi_reg_bid),
    .m_axi_osc1_aclk(m_axi_osc1_aclk),
    .m_axi_osc1_aresetn(m_axi_osc1_aresetn),
    .m_axi_osc1_awaddr(m_axi_osc1_awaddr),
    .m_axi_osc1_awlen(m_axi_osc1_awlen),
    .m_axi_osc1_awsize(m_axi_osc1_awsize),
    .m_axi_osc1_awburst(m_axi_osc1_awburst),
    .m_axi_osc1_awprot(m_axi_osc1_awprot),
    .m_axi_osc1_awcache(m_axi_osc1_awcache),
    .m_axi_osc1_awvalid(m_axi_osc1_awvalid),
    .m_axi_osc1_awready(m_axi_osc1_awready),
    .m_axi_osc1_wdata(m_axi_osc1_wdata),
    .m_axi_osc1_wstrb(m_axi_osc1_wstrb),
    .m_axi_osc1_wlast(m_axi_osc1_wlast),
    .m_axi_osc1_wvalid(m_axi_osc1_wvalid),
    .m_axi_osc1_wready(m_axi_osc1_wready),
    .m_axi_osc1_bresp(m_axi_osc1_bresp),
    .m_axi_osc1_bvalid(m_axi_osc1_bvalid),
    .m_axi_osc1_bready(m_axi_osc1_bready),
    .m_axi_osc2_aclk(m_axi_osc2_aclk),
    .m_axi_osc2_aresetn(m_axi_osc2_aresetn),
    .m_axi_osc2_awaddr(m_axi_osc2_awaddr),
    .m_axi_osc2_awlen(m_axi_osc2_awlen),
    .m_axi_osc2_awsize(m_axi_osc2_awsize),
    .m_axi_osc2_awburst(m_axi_osc2_awburst),
    .m_axi_osc2_awprot(m_axi_osc2_awprot),
    .m_axi_osc2_awcache(m_axi_osc2_awcache),
    .m_axi_osc2_awvalid(m_axi_osc2_awvalid),
    .m_axi_osc2_awready(m_axi_osc2_awready),
    .m_axi_osc2_wdata(m_axi_osc2_wdata),
    .m_axi_osc2_wstrb(m_axi_osc2_wstrb),
    .m_axi_osc2_wlast(m_axi_osc2_wlast),
    .m_axi_osc2_wvalid(m_axi_osc2_wvalid),
    .m_axi_osc2_wready(m_axi_osc2_wready),
    .m_axi_osc2_bresp(m_axi_osc2_bresp),
    .m_axi_osc2_bvalid(m_axi_osc2_bvalid),
    .m_axi_osc2_bready(m_axi_osc2_bready),
    .m_axi_osc3_aclk(m_axi_osc3_aclk),
    .m_axi_osc3_aresetn(m_axi_osc3_aresetn),
    .m_axi_osc3_awaddr(m_axi_osc3_awaddr),
    .m_axi_osc3_awlen(m_axi_osc3_awlen),
    .m_axi_osc3_awsize(m_axi_osc3_awsize),
    .m_axi_osc3_awburst(m_axi_osc3_awburst),
    .m_axi_osc3_awprot(m_axi_osc3_awprot),
    .m_axi_osc3_awcache(m_axi_osc3_awcache),
    .m_axi_osc3_awvalid(m_axi_osc3_awvalid),
    .m_axi_osc3_awready(m_axi_osc3_awready),
    .m_axi_osc3_wdata(m_axi_osc3_wdata),
    .m_axi_osc3_wstrb(m_axi_osc3_wstrb),
    .m_axi_osc3_wlast(m_axi_osc3_wlast),
    .m_axi_osc3_wvalid(m_axi_osc3_wvalid),
    .m_axi_osc3_wready(m_axi_osc3_wready),
    .m_axi_osc3_bresp(m_axi_osc3_bresp),
    .m_axi_osc3_bvalid(m_axi_osc3_bvalid),
    .m_axi_osc3_bready(m_axi_osc3_bready),
    .m_axi_osc4_aclk(m_axi_osc4_aclk),
    .m_axi_osc4_aresetn(m_axi_osc4_aresetn),
    .m_axi_osc4_awaddr(m_axi_osc4_awaddr),
    .m_axi_osc4_awlen(m_axi_osc4_awlen),
    .m_axi_osc4_awsize(m_axi_osc4_awsize),
    .m_axi_osc4_awburst(m_axi_osc4_awburst),
    .m_axi_osc4_awprot(m_axi_osc4_awprot),
    .m_axi_osc4_awcache(m_axi_osc4_awcache),
    .m_axi_osc4_awvalid(m_axi_osc4_awvalid),
    .m_axi_osc4_awready(m_axi_osc4_awready),
    .m_axi_osc4_wdata(m_axi_osc4_wdata),
    .m_axi_osc4_wstrb(m_axi_osc4_wstrb),
    .m_axi_osc4_wlast(m_axi_osc4_wlast),
    .m_axi_osc4_wvalid(m_axi_osc4_wvalid),
    .m_axi_osc4_wready(m_axi_osc4_wready),
    .m_axi_osc4_bresp(m_axi_osc4_bresp),
    .m_axi_osc4_bvalid(m_axi_osc4_bvalid),
    .m_axi_osc4_bready(m_axi_osc4_bready)
  );
endmodule
