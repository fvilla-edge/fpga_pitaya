#!/bin/bash
# Etapa 4b (RedPitaya-FPGA): simulacion standalone (xvlog/xelab/xsim, sin
# GUI, sin IP de Xilinx) del bloque bandpass_biquad.v con coeficientes NO
# triviales (pasabajos de juguete RBJ), contra vectores golden generados
# en Python replicando la misma aritmetica de punto fijo. Ver
# tbn/tb_bandpass_biquad_lowpass.sv para el detalle.
set -e
cd "$(dirname "$0")/prj/stream_app"

rm -rf xsim_bandpass xsim.dir
mkdir -p xsim_bandpass
cd xsim_bandpass

xvlog -sv \
  ../ip/rp_oscilloscope/bandpass_biquad.v \
  ../tbn/tb_bandpass_biquad_lowpass.sv

xelab -debug typical tb_bandpass_biquad_lowpass -s tb_bandpass_biquad_lowpass_sim -timescale 1ns/1ps

xsim tb_bandpass_biquad_lowpass_sim -runall
