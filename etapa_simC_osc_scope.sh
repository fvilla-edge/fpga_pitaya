#!/bin/bash
# Simulacion C (RedPitaya-FPGA): simulacion standalone (xvlog/xelab/xsim,
# sin GUI, sin IP de Xilinx) de rp_oscilloscope.v REAL completo
# (NUM_CHANNELS=2), sobre lo ya validado en la Simulacion B. Ver
# tbn/tb_rp_oscilloscope_simC.sv y README.md, seccion "Simulacion: estado
# y plan", para el detalle.
set -e
cd "$(dirname "$0")/prj/stream_app"

rm -rf xsim_simC xsim.dir
mkdir -p xsim_simC
cd xsim_simC

xvlog -sv \
  ../../../rtl/interface/axi4_if.sv \
  ../../../rtl/interface/sys_bus_if.sv \
  ../../../rtl/axi4_slave.sv \
  ../../../rtl/sync_rw_single.v \
  ../../../rtl/divide.v \
  ../../../tbn/axi_master_model.sv \
  ../ip/rp_oscilloscope/scope_cfg.sv \
  ../ip/rp_oscilloscope/osc_filter.v \
  ../ip/rp_oscilloscope/osc_calib.v \
  ../ip/rp_oscilloscope/osc_decimator.v \
  ../ip/rp_oscilloscope/bandpass_biquad.v \
  ../ip/rp_oscilloscope/bandpass_filter.v \
  ../ip/rp_oscilloscope/area_kurtosis_accum.v \
  ../ip/rp_oscilloscope/osc_trigger.v \
  ../ip/rp_oscilloscope/osc_aquire.v \
  ../tbn/sim_stub_rp_dma_s2mm.sv \
  ../ip/rp_oscilloscope/osc_top.v \
  ../ip/rp_oscilloscope/rp_oscilloscope.v \
  ../tbn/tb_rp_oscilloscope_simC.sv

xelab -debug typical tb_rp_oscilloscope_simC -s tb_rp_oscilloscope_simC_sim -timescale 1ns/1ps

xsim tb_rp_oscilloscope_simC_sim -runall
