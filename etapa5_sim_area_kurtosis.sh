#!/bin/bash
# Etapa 5 (RedPitaya-FPGA): simulacion standalone (xvlog/xelab/xsim, sin
# GUI, sin IP de Xilinx) de area_kurtosis_accum.v. Ver
# tbn/tb_area_kurtosis_accum.sv para el detalle.
set -e
cd "$(dirname "$0")/prj/stream_app"

rm -rf xsim_area_kurtosis xsim.dir
mkdir -p xsim_area_kurtosis
cd xsim_area_kurtosis

xvlog -sv \
  ../ip/rp_oscilloscope/area_kurtosis_accum.v \
  ../tbn/tb_area_kurtosis_accum.sv

xelab -debug typical tb_area_kurtosis_accum -s tb_area_kurtosis_accum_sim -timescale 1ns/1ps

xsim tb_area_kurtosis_accum_sim -runall
