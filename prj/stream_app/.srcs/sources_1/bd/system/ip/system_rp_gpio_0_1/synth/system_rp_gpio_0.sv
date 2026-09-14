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


// IP VLNV: redpitaya.com:user:rp_gpio:1.0
// IP Revision: 44

(* X_CORE_INFO = "rp_gpio,Vivado 2020.1" *)
(* CHECK_LICENSE_TYPE = "system_rp_gpio_0,rp_gpio,{}" *)
(* IP_DEFINITION_SOURCE = "package_project" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module system_rp_gpio_0 (
  clk,
  rst_n,
  intr,
  exp_p_io,
  exp_n_io,
  event_ip_trig,
  event_ip_stop,
  event_ip_start,
  event_ip_reset,
  trig_ip,
  la_event_op,
  la_trig_op,
  gpio_trig_o,
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
  s_axi_reg_wlast,
  s_axi_reg_awid,
  s_axi_reg_arid,
  s_axi_reg_wid,
  s_axi_reg_rid,
  s_axi_reg_bid,
  m_axi_gpio_out_aclk,
  m_axi_gpio_out_aresetn,
  m_axi_gpio_arid,
  m_axi_gpio_araddr,
  m_axi_gpio_arlen,
  m_axi_gpio_arsize,
  m_axi_gpio_arburst,
  m_axi_gpio_arlock,
  m_axi_gpio_arcache,
  m_axi_gpio_arprot,
  m_axi_gpio_arvalid,
  m_axi_gpio_arready,
  m_axi_gpio_rid,
  m_axi_gpio_rdata,
  m_axi_gpio_rresp,
  m_axi_gpio_rlast,
  m_axi_gpio_rvalid,
  m_axi_gpio_rready,
  m_axi_gpio_in_aclk,
  m_axi_gpio_in_aresetn,
  m_axi_gpio_awaddr,
  m_axi_gpio_awlen,
  m_axi_gpio_awsize,
  m_axi_gpio_awburst,
  m_axi_gpio_awprot,
  m_axi_gpio_awcache,
  m_axi_gpio_awvalid,
  m_axi_gpio_awready,
  m_axi_gpio_wdata,
  m_axi_gpio_wstrb,
  m_axi_gpio_wlast,
  m_axi_gpio_wvalid,
  m_axi_gpio_wready,
  m_axi_gpio_bresp,
  m_axi_gpio_bvalid,
  m_axi_gpio_bready
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
inout wire [7 : 0] exp_p_io;
inout wire [7 : 0] exp_n_io;
input wire [4 : 0] event_ip_trig;
input wire [4 : 0] event_ip_stop;
input wire [4 : 0] event_ip_start;
input wire [4 : 0] event_ip_reset;
input wire [5 : 0] trig_ip;
output wire [3 : 0] la_event_op;
output wire la_trig_op;
output wire gpio_trig_o;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_reg_aclk, ASSOCIATED_RESET s_axi_reg_aresetn, ASSOCIATED_BUSIF s_axi_reg, FREQ_HZ 50000000, FREQ_TOLERANCE_HZ 0, PHASE 0.000, CLK_DOMAIN system_processing_system7_0_0_FCLK_CLK2, INSERT_VIP 0" *)
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
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_reg WLAST" *)
input wire s_axi_reg_wlast;
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
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_gpio_out_aclk, ASSOCIATED_RESET m_axi_gpio_out_aresetn, ASSOCIATED_BUSIF axi_gpio_out, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 m_axi_gpio_out_aclk CLK" *)
input wire m_axi_gpio_out_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_gpio_out_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 m_axi_gpio_out_aresetn RST" *)
input wire m_axi_gpio_out_aresetn;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in ARID" *)
output wire [3 : 0] m_axi_gpio_arid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in ARADDR" *)
output wire [31 : 0] m_axi_gpio_araddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in ARLEN" *)
output wire [3 : 0] m_axi_gpio_arlen;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in ARSIZE" *)
output wire [2 : 0] m_axi_gpio_arsize;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in ARBURST" *)
output wire [1 : 0] m_axi_gpio_arburst;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in ARLOCK" *)
output wire [1 : 0] m_axi_gpio_arlock;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in ARCACHE" *)
output wire [3 : 0] m_axi_gpio_arcache;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in ARPROT" *)
output wire [2 : 0] m_axi_gpio_arprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in ARVALID" *)
output wire m_axi_gpio_arvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in ARREADY" *)
input wire m_axi_gpio_arready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in RID" *)
input wire [3 : 0] m_axi_gpio_rid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in RDATA" *)
input wire [63 : 0] m_axi_gpio_rdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in RRESP" *)
input wire [1 : 0] m_axi_gpio_rresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in RLAST" *)
input wire m_axi_gpio_rlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in RVALID" *)
input wire m_axi_gpio_rvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME axi_gpio_in, DATA_WIDTH 64, PROTOCOL AXI3, FREQ_HZ 125000000, ID_WIDTH 4, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_ONLY, HAS_BURST 1, HAS_LOCK 1, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 0, HAS_BRESP 0, HAS_RRESP 1, SUPPORTS_NARROW_BURST 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 16, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1\
, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_in RREADY" *)
output wire m_axi_gpio_rready;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_gpio_in_aclk, ASSOCIATED_RESET m_axi_gpio_in_aresetn, ASSOCIATED_BUSIF axi_gpio_in, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 m_axi_gpio_in_aclk CLK" *)
input wire m_axi_gpio_in_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_gpio_in_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 m_axi_gpio_in_aresetn RST" *)
input wire m_axi_gpio_in_aresetn;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out AWADDR" *)
output wire [31 : 0] m_axi_gpio_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out AWLEN" *)
output wire [7 : 0] m_axi_gpio_awlen;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out AWSIZE" *)
output wire [2 : 0] m_axi_gpio_awsize;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out AWBURST" *)
output wire [1 : 0] m_axi_gpio_awburst;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out AWPROT" *)
output wire [2 : 0] m_axi_gpio_awprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out AWCACHE" *)
output wire [3 : 0] m_axi_gpio_awcache;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out AWVALID" *)
output wire m_axi_gpio_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out AWREADY" *)
input wire m_axi_gpio_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out WDATA" *)
output wire [31 : 0] m_axi_gpio_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out WSTRB" *)
output wire [7 : 0] m_axi_gpio_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out WLAST" *)
output wire m_axi_gpio_wlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out WVALID" *)
output wire m_axi_gpio_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out WREADY" *)
input wire m_axi_gpio_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out BRESP" *)
input wire [1 : 0] m_axi_gpio_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out BVALID" *)
input wire m_axi_gpio_bvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME axi_gpio_out, DATA_WIDTH 32, PROTOCOL AXI4, FREQ_HZ 125000000, ID_WIDTH 0, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE WRITE_ONLY, HAS_BURST 1, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 0, SUPPORTS_NARROW_BURST 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 256, PHASE 0.0, CLK_DOMAIN /clk_gen_clk_out1, NUM_READ_THREADS 1, NUM_WRITE_THREAD\
S 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_gpio_out BREADY" *)
output wire m_axi_gpio_bready;

  rp_gpio #(
    .S_AXI_REG_ADDR_BITS(20),
    .M_AXI_GPIO_ADDR_BITS(32),
    .M_AXI_GPIO_DATA_BITS(64),
    .GPIO_BITS(8),
    .EVENT_SRC_NUM(5),
    .TRIG_SRC_NUM(6),
    .ID_WIDTHS(12)
  ) inst (
    .clk(clk),
    .rst_n(rst_n),
    .intr(intr),
    .exp_p_io(exp_p_io),
    .exp_n_io(exp_n_io),
    .event_ip_trig(event_ip_trig),
    .event_ip_stop(event_ip_stop),
    .event_ip_start(event_ip_start),
    .event_ip_reset(event_ip_reset),
    .trig_ip(trig_ip),
    .la_event_op(la_event_op),
    .la_trig_op(la_trig_op),
    .gpio_trig_o(gpio_trig_o),
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
    .s_axi_reg_wlast(s_axi_reg_wlast),
    .s_axi_reg_awid(s_axi_reg_awid),
    .s_axi_reg_arid(s_axi_reg_arid),
    .s_axi_reg_wid(s_axi_reg_wid),
    .s_axi_reg_rid(s_axi_reg_rid),
    .s_axi_reg_bid(s_axi_reg_bid),
    .m_axi_gpio_out_aclk(m_axi_gpio_out_aclk),
    .m_axi_gpio_out_aresetn(m_axi_gpio_out_aresetn),
    .m_axi_gpio_arid(m_axi_gpio_arid),
    .m_axi_gpio_araddr(m_axi_gpio_araddr),
    .m_axi_gpio_arlen(m_axi_gpio_arlen),
    .m_axi_gpio_arsize(m_axi_gpio_arsize),
    .m_axi_gpio_arburst(m_axi_gpio_arburst),
    .m_axi_gpio_arlock(m_axi_gpio_arlock),
    .m_axi_gpio_arcache(m_axi_gpio_arcache),
    .m_axi_gpio_arprot(m_axi_gpio_arprot),
    .m_axi_gpio_arvalid(m_axi_gpio_arvalid),
    .m_axi_gpio_arready(m_axi_gpio_arready),
    .m_axi_gpio_rid(m_axi_gpio_rid),
    .m_axi_gpio_rdata(m_axi_gpio_rdata),
    .m_axi_gpio_rresp(m_axi_gpio_rresp),
    .m_axi_gpio_rlast(m_axi_gpio_rlast),
    .m_axi_gpio_rvalid(m_axi_gpio_rvalid),
    .m_axi_gpio_rready(m_axi_gpio_rready),
    .m_axi_gpio_in_aclk(m_axi_gpio_in_aclk),
    .m_axi_gpio_in_aresetn(m_axi_gpio_in_aresetn),
    .m_axi_gpio_awaddr(m_axi_gpio_awaddr),
    .m_axi_gpio_awlen(m_axi_gpio_awlen),
    .m_axi_gpio_awsize(m_axi_gpio_awsize),
    .m_axi_gpio_awburst(m_axi_gpio_awburst),
    .m_axi_gpio_awprot(m_axi_gpio_awprot),
    .m_axi_gpio_awcache(m_axi_gpio_awcache),
    .m_axi_gpio_awvalid(m_axi_gpio_awvalid),
    .m_axi_gpio_awready(m_axi_gpio_awready),
    .m_axi_gpio_wdata(m_axi_gpio_wdata),
    .m_axi_gpio_wstrb(m_axi_gpio_wstrb),
    .m_axi_gpio_wlast(m_axi_gpio_wlast),
    .m_axi_gpio_wvalid(m_axi_gpio_wvalid),
    .m_axi_gpio_wready(m_axi_gpio_wready),
    .m_axi_gpio_bresp(m_axi_gpio_bresp),
    .m_axi_gpio_bvalid(m_axi_gpio_bvalid),
    .m_axi_gpio_bready(m_axi_gpio_bready)
  );
endmodule
