#!/bin/bash
# Lectura de DIO (Sand Monitoring, rama lectura-dio): simulacion standalone
# (xvlog/xelab/xsim, sin GUI) de dio_lectura, el modulo agregado al final de
# rp_gpio.sv: DIO2_P fijo como entrada + registro 0x78 con los pines
# sincronizados. Compila rp_gpio.sv entero con SIMULATION (para que falle si
# el cambio rompe la sintaxis del archivo), pero elabora solo el testbench.
# Ver tbn/tb_dio_lectura.sv.
set -e
cd "$(dirname "$0")/prj/stream_app"

rm -rf xsim_dio xsim.dir
mkdir -p xsim_dio
cd xsim_dio

xvlog -sv -d SIMULATION \
  ../../../rtl/rtl/interface/axi4_stream_if.sv \
  ../rtl/rtl/rp_gpio/rp_gpio.sv \
  ../tbn/tb_dio_lectura.sv

xelab -debug typical tb_dio_lectura -s tb_dio_lectura_sim -timescale 1ns/1ps

xsim tb_dio_lectura_sim -runall
