//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.1 (lin64) Build 2902540 Wed May 27 19:54:35 MDT 2020
//Date        : Tue Jun 30 09:18:31 2026
//Host        : facu-edge running 64-bit Ubuntu 24.04.4 LTS
//Command     : generate_target system_wrapper.bd
//Design      : system_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module system_wrapper
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FCLK_CLK0,
    FCLK_CLK1,
    FCLK_CLK2,
    FCLK_CLK3,
    FCLK_RESET0_N,
    FCLK_RESET1_N,
    FCLK_RESET2_N,
    FCLK_RESET3_N,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    In10_0,
    In11_0,
    In12_0,
    In13_0,
    In1_0,
    In2_0,
    In3_0,
    In4_0,
    In5_0,
    In6_0,
    In7_0,
    In8_0,
    In9_0,
    adc_clk,
    adc_data_ch1,
    adc_data_ch2,
    clk_out,
    clksel,
    dac_dat_a,
    dac_dat_b,
    daisy_slave,
    gpio_n,
    gpio_p,
    gpio_trig,
    loopback_sel,
    rstn_out,
    trig_in,
    trig_out);
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  output FCLK_CLK0;
  output FCLK_CLK1;
  output FCLK_CLK2;
  output FCLK_CLK3;
  output FCLK_RESET0_N;
  output FCLK_RESET1_N;
  output FCLK_RESET2_N;
  output FCLK_RESET3_N;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  input [0:0]In10_0;
  input [0:0]In11_0;
  input [0:0]In12_0;
  input [0:0]In13_0;
  input [0:0]In1_0;
  input [0:0]In2_0;
  input [0:0]In3_0;
  input [0:0]In4_0;
  input [0:0]In5_0;
  input [0:0]In6_0;
  input [0:0]In7_0;
  input [0:0]In8_0;
  input [0:0]In9_0;
  input adc_clk;
  input [13:0]adc_data_ch1;
  input [13:0]adc_data_ch2;
  output clk_out;
  output clksel;
  output [15:0]dac_dat_a;
  output [15:0]dac_dat_b;
  input daisy_slave;
  inout [7:0]gpio_n;
  inout [7:0]gpio_p;
  output gpio_trig;
  output [7:0]loopback_sel;
  output [0:0]rstn_out;
  input trig_in;
  output trig_out;

  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FCLK_CLK0;
  wire FCLK_CLK1;
  wire FCLK_CLK2;
  wire FCLK_CLK3;
  wire FCLK_RESET0_N;
  wire FCLK_RESET1_N;
  wire FCLK_RESET2_N;
  wire FCLK_RESET3_N;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire [0:0]In10_0;
  wire [0:0]In11_0;
  wire [0:0]In12_0;
  wire [0:0]In13_0;
  wire [0:0]In1_0;
  wire [0:0]In2_0;
  wire [0:0]In3_0;
  wire [0:0]In4_0;
  wire [0:0]In5_0;
  wire [0:0]In6_0;
  wire [0:0]In7_0;
  wire [0:0]In8_0;
  wire [0:0]In9_0;
  wire adc_clk;
  wire [13:0]adc_data_ch1;
  wire [13:0]adc_data_ch2;
  wire clk_out;
  wire clksel;
  wire [15:0]dac_dat_a;
  wire [15:0]dac_dat_b;
  wire daisy_slave;
  wire [7:0]gpio_n;
  wire [7:0]gpio_p;
  wire gpio_trig;
  wire [7:0]loopback_sel;
  wire [0:0]rstn_out;
  wire trig_in;
  wire trig_out;

  system system_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FCLK_CLK0(FCLK_CLK0),
        .FCLK_CLK1(FCLK_CLK1),
        .FCLK_CLK2(FCLK_CLK2),
        .FCLK_CLK3(FCLK_CLK3),
        .FCLK_RESET0_N(FCLK_RESET0_N),
        .FCLK_RESET1_N(FCLK_RESET1_N),
        .FCLK_RESET2_N(FCLK_RESET2_N),
        .FCLK_RESET3_N(FCLK_RESET3_N),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .In10_0(In10_0),
        .In11_0(In11_0),
        .In12_0(In12_0),
        .In13_0(In13_0),
        .In1_0(In1_0),
        .In2_0(In2_0),
        .In3_0(In3_0),
        .In4_0(In4_0),
        .In5_0(In5_0),
        .In6_0(In6_0),
        .In7_0(In7_0),
        .In8_0(In8_0),
        .In9_0(In9_0),
        .adc_clk(adc_clk),
        .adc_data_ch1(adc_data_ch1),
        .adc_data_ch2(adc_data_ch2),
        .clk_out(clk_out),
        .clksel(clksel),
        .dac_dat_a(dac_dat_a),
        .dac_dat_b(dac_dat_b),
        .daisy_slave(daisy_slave),
        .gpio_n(gpio_n),
        .gpio_p(gpio_p),
        .gpio_trig(gpio_trig),
        .loopback_sel(loopback_sel),
        .rstn_out(rstn_out),
        .trig_in(trig_in),
        .trig_out(trig_out));
endmodule
