#!/bin/bash
# Etapa 4c (RedPitaya-FPGA): simulacion standalone (xvlog/xelab/xsim, sin
# GUI, sin IP de Xilinx) del pasabanda real (bandpass_filter.v, 2
# secciones biquad en cascada) contra vectores golden generados en Python
# (respuesta en frecuencia + chequeo de limit-cycle + bit-exacto). Ver
# tbn/tb_bandpass_filter.sv y tbn/vectores/generar_etapa4c.py.
set -e
cd "$(dirname "$0")/prj/stream_app"

rm -rf xsim_bandpass xsim.dir
mkdir -p xsim_bandpass
cd xsim_bandpass

xvlog -sv \
  ../ip/rp_oscilloscope/bandpass_biquad.v \
  ../ip/rp_oscilloscope/bandpass_filter.v \
  ../tbn/tb_bandpass_filter.sv

xelab -debug typical tb_bandpass_filter -s tb_bandpass_filter_sim -timescale 1ns/1ps

xsim tb_bandpass_filter_sim -runall
