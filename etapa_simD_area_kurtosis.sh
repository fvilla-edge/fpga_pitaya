#!/bin/bash
# Simulacion D (RedPitaya-FPGA): inyecta una captura real de arena
# (datos_campo/ en Sand Monitoring) en osc_top.v REAL y compara el
# area/kurtosis de HW contra la referencia de software. Requiere haber
# corrido antes tbn/vectores/extraer_datos_reales_simD.py (venv de este
# repo: .venv/bin/python) para generar los .mem de estimulo. Ver
# tbn/tb_area_kurtosis_simD.sv y README.md, seccion "Simulacion: estado
# y plan".
set -e
cd "$(dirname "$0")"

if [ ! -f prj/stream_app/tbn/vectores/stimulus_evento_simD.mem ]; then
  echo "Falta stimulus_evento_simD.mem - corriendo antes .venv/bin/python prj/stream_app/tbn/vectores/extraer_datos_reales_simD.py"
  .venv/bin/python prj/stream_app/tbn/vectores/extraer_datos_reales_simD.py
fi

cd prj/stream_app

rm -rf xsim_simD xsim.dir
mkdir -p xsim_simD
cd xsim_simD

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
  ../tbn/tb_area_kurtosis_simD.sv

xelab -debug typical tb_area_kurtosis_simD -s tb_area_kurtosis_simD_sim -timescale 1ns/1ps

xsim tb_area_kurtosis_simD_sim -runall
