#!/bin/bash
# Simulacion D (dec64, para MOSTRAR el corrimiento de banda ya
# documentado): corre 3 ventanas reales de
# datos/Dia miercoles 3 de Sept/lote3_mono (dec64, fs=1953125Hz) contra
# el osc_top.v con los MISMOS coeficientes fijos de dec32 (sin
# recalcular). Requiere haber corrido antes
# tbn/vectores/extraer_dec64_simD.py. Ver tb_area_kurtosis_dec64corr_simD.sv.
set -e
cd "$(dirname "$0")"

if [ ! -f prj/stream_app/tbn/vectores/dec64_simD/manifest.json ]; then
  echo "Falta dec64_simD/ - corriendo antes .venv/bin/python prj/stream_app/tbn/vectores/extraer_dec64_simD.py"
  .venv/bin/python prj/stream_app/tbn/vectores/extraer_dec64_simD.py
fi

cd prj/stream_app

rm -rf xsim_dec64corr_simD xsim.dir
mkdir -p xsim_dec64corr_simD
cd xsim_dec64corr_simD

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
  ../tbn/tb_area_kurtosis_dec64corr_simD.sv

xelab -debug typical tb_area_kurtosis_dec64corr_simD -s tb_area_kurtosis_dec64corr_simD_sim -timescale 1ns/1ps

xsim tb_area_kurtosis_dec64corr_simD_sim -runall
