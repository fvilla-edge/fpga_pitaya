#!/bin/bash
# Simulacion B (RedPitaya-FPGA): simulacion standalone (xvlog/xelab/xsim,
# sin GUI, sin IP de Xilinx) de osc_top.v REAL completo -no mas diag5_i a
# mano como en la Simulacion A (ver etapa2_sim_diag5.sh). El bloque de DMA
# (rp_dma_s2mm.v, que usa la IP de Xilinx fifo_axi_data) se reemplaza por
# un stub (sim_stub_rp_dma_s2mm.sv) - ver ese archivo y
# tbn/tb_osc_top_simB.sv para el detalle de por que hizo falta y que se
# prueba en esta etapa. Ver README.md, seccion "Simulacion: estado y
# plan", para donde encaja esto en la escalera A->B->C->D.
set -e
cd "$(dirname "$0")/prj/stream_app"

rm -rf xsim_simB xsim.dir
mkdir -p xsim_simB
cd xsim_simB

xvlog -sv \
  ../../../rtl/rtl/divide.v \
  ../rtl/rtl/rp_oscilloscope/osc_filter.v \
  ../rtl/rtl/rp_oscilloscope/osc_calib.v \
  ../rtl/rtl/rp_oscilloscope/osc_decimator.v \
  ../rtl/rtl/rp_oscilloscope/bandpass_biquad.v \
  ../rtl/rtl/rp_oscilloscope/bandpass_filter.v \
  ../rtl/rtl/rp_oscilloscope/area_kurtosis_accum.v \
  ../rtl/rtl/rp_oscilloscope/osc_trigger.v \
  ../rtl/rtl/rp_oscilloscope/osc_aquire.v \
  ../tbn/sim_stub_rp_dma_s2mm.sv \
  ../rtl/rtl/rp_oscilloscope/osc_top.v \
  ../tbn/tb_osc_top_simB.sv

xelab -debug typical tb_osc_top_simB -s tb_osc_top_simB_sim -timescale 1ns/1ps

xsim tb_osc_top_simB_sim -runall
