#!/bin/bash
# Etapa 3 (RedPitaya-FPGA): simulacion standalone (xvlog/xelab/xsim, sin
# GUI, sin IP de Xilinx) del bloque bandpass_biquad.v en modo "pasamanos"
# (transparente). Ver tbn/tb_bandpass_biquad_passthrough.sv para el detalle.
set -e
cd "$(dirname "$0")/prj/stream_app"

rm -rf xsim_bandpass xsim.dir
mkdir -p xsim_bandpass
cd xsim_bandpass

xvlog -sv \
  ../ip/rp_oscilloscope/bandpass_biquad.v \
  ../tbn/tb_bandpass_biquad_passthrough.sv

xelab -debug typical tb_bandpass_biquad_passthrough -s tb_bandpass_biquad_sim -timescale 1ns/1ps

xsim tb_bandpass_biquad_sim -runall
