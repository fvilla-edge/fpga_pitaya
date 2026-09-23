#!/bin/bash
# Etapa 2 (RedPitaya-FPGA): simulacion standalone (xvlog/xelab/xsim, sin GUI,
# sin pasar por el proyecto/IP-integrator de Vivado) del registro nuevo
# DIAG_REG5 en scope_cfg.sv. Ver tbn/tb_scope_cfg_diag5.sv para el detalle
# del test y el README para por que no se simula rp_oscilloscope.v completo
# todavia (depende de un core Xilinx FIFO Generator via IP catalog).
set -e
cd "$(dirname "$0")/prj/stream_app"

rm -rf xsim_diag5 xsim.dir
mkdir -p xsim_diag5
cd xsim_diag5

xvlog -sv \
  ../../../rtl/rtl/interface/axi4_if.sv \
  ../../../rtl/rtl/interface/sys_bus_if.sv \
  ../../../rtl/rtl/axi4_slave.sv \
  ../../../rtl/rtl/sync_rw_single.v \
  ../../../tbn/axi_master_model.sv \
  ../rtl/rtl/rp_oscilloscope/scope_cfg.sv \
  ../tbn/tb_scope_cfg_diag5.sv

xelab -debug typical tb_scope_cfg_diag5 -s tb_scope_cfg_diag5_sim -timescale 1ns/1ps

xsim tb_scope_cfg_diag5_sim -runall
