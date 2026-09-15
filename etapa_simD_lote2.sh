#!/bin/bash
# Simulacion D (extension, muestreo mas amplio): corre 6 ventanas reales
# mas (evento fuerte, moderado, y reposo cerca del umbral) de
# datos/Dia miercoles 3 de Sept/lote1_mono, ademas del par original de
# datos_campo/. Requiere haber corrido antes
# tbn/vectores/extraer_lote_simD2.py. Ver tb_area_kurtosis_lote2_simD.sv.
set -e
cd "$(dirname "$0")"

if [ ! -f prj/stream_app/tbn/vectores/lote2_simD/manifest.json ]; then
  echo "Falta lote2_simD/ - corriendo antes .venv/bin/python prj/stream_app/tbn/vectores/extraer_lote_simD2.py"
  .venv/bin/python prj/stream_app/tbn/vectores/extraer_lote_simD2.py
fi

cd prj/stream_app

rm -rf xsim_simD_lote2 xsim.dir
mkdir -p xsim_simD_lote2
cd xsim_simD_lote2

xvlog -sv \
  ../../../rtl/divide.v \
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
  ../tbn/tb_area_kurtosis_lote2_simD.sv

xelab -debug typical tb_area_kurtosis_lote2_simD -s tb_area_kurtosis_lote2_simD_sim -timescale 1ns/1ps

xsim tb_area_kurtosis_lote2_simD_sim -runall
