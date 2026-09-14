# Cómo compilar (proyecto `stream_app`)

Referencia práctica de comandos. Se actualiza cada vez que cambien los pasos
de build (por ejemplo, cuando se agregue RTL nuevo en la Etapa 2 en
adelante). Para el "por qué" de cada decisión y el historial del plan, ver
`README.md` — este documento es solo "cómo se ejecuta".

## Requisitos

- Vivado 2020.1 instalado en `/tools/Xilinx/Vivado/2020.1`, con licencia.
- En esta máquina (`facu-edge`) ya está en el `PATH` — confirmar con
  `which vivado` antes de compilar. Si en otra máquina no lo está, primero:
  ```
  source /tools/Xilinx/Vivado/2020.1/settings64.sh
  ```

## Comandos básicos

Todos se corren **desde la raíz del repo** (`~/RedPitaya-FPGA-Release_2025.2`).

**Compilar solo el bitstream** (lo que hace falta para iterar sobre el
filtro — no genera FSBL ni device tree):
```
make PRJ=stream_app MODEL=Z10 prj/stream_app/out/red_pitaya.bit
```
Tarda **~5 minutos** (medido 2026-09-14, build limpio, `real 5m08s`).

**Limpiar antes de una recompilación real desde cero** (borra
`out/`, `.Xil/`, `.srcs/`, `sdk/`, `project/` de `stream_app` — no toca
RTL ni nada versionado a mano):
```
make PRJ=stream_app clean
```
Sin este paso, si `out/red_pitaya.bit` ya existe, `make` puede no
recompilar nada (lo considera actualizado).

**Generar además el `.bin`** (para `bootgen`, hace falta para flashear):
```
make PRJ=stream_app MODEL=Z10 prj/stream_app/out/red_pitaya.bit.bin
```

**Target `all`** (bitstream + FSBL + device tree + `.bin`) — **no
funciona todavía en esta máquina**: requiere `xsct`/`hsi` (parte de
Xilinx Vitis/SDK, no instalado). No hace falta para el trabajo del
filtro, solo para armar la imagen de boot completa (kernel+rootfs+FSBL).

**Simulación con `make sim` — NO USAR, no funciona en este repo.**
Se probó (2026-09-14): el target abre la GUI de Vivado (no tiene
`-mode batch`) y además no existe ningún `top_tb` para `stream_app`+Z10
(solo para otras variantes del proyecto) — se cuelga esperando una
ventana que nunca hace nada útil. Ver la sección "Simulación: estado y
plan" del `README.md` para el detalle y el plan de arreglarlo de fondo.

**Simulación que SÍ funciona hoy — test del registro `DIAG_REG5`
("hola mundo" de la Etapa 2):**
```
./etapa2_sim_diag5.sh
```
Corre en segundos (no minutos), sin GUI, sin proyecto Vivado — usa
`xvlog`/`xelab`/`xsim` (línea de comandos, vienen con Vivado) para
compilar y simular SOLO `scope_cfg.sv` (el decodificador de registros
AXI) con un testbench dedicado
(`prj/stream_app/tbn/tb_scope_cfg_diag5.sv`). Al final imprime:
```
RESULTADO: TODOS LOS CHECKS PASARON (7/7)
```
Si en cambio dice `CHECKS FALLARON` o `TIMEOUT`, algo se rompió en el
decodificador de registros — revisar la salida completa arriba de esa
línea, cada check dice `OK`/`FAIL` con la dirección y el valor leído.
No valida el contador de `osc_top.v` ni el cableado completo de
`rp_oscilloscope.v` todavía (ver plan en el README) — solo el
decodificador de direcciones.

**Simulación del bloque del filtro nuevo (Etapa 3, modo pasamanos):**
```
./etapa3_sim_bandpass.sh
```
Mismo estilo que la anterior (segundos, sin GUI). Prueba
`bandpass_biquad.v` solo, con datos/valid/ready aleatorios durante 200
ciclos, confirmando que es transparente (sale lo mismo que entra). Va a
dejar de ser un simple "diff" cuando la Etapa 4 le agregue la matemática
real del biquad — en ese momento el testbench cambia de "es igual a la
entrada" a "coincide con lo que da `scipy.signal.lfilter` con los mismos
coeficientes".

**Etapa 4a (coeficientes triviales, `b0=1.0` resto en 0)** ya no tiene
script propio — quedó superada por la Etapa 4b (mismo módulo, coeficientes
reemplazados) y el test que la validaba (`tb_bandpass_biquad_unity.sv`,
297/297 checks) se borró porque ya no aplica al código actual. El
resultado sigue documentado en el README y en el historial de git
(commit de la Etapa 4a) si hace falta revisarlo.

**Simulación del biquad con coeficientes reales de un pasabajos
(Etapa 4b):**
```
./etapa4b_sim_bandpass.sh
```
Mismo estilo (segundos, sin GUI). Compara contra vectores golden
precalculados (`tbn/vectores/etapa4b_input.mem` /
`etapa4b_expected.mem`) generados con un modelo en Python que replica
EXACTO la misma aritmética de punto fijo del RTL (no es una comparación
contra el filtro ideal en punto flotante — es bit exacto contra "lo que
este punto fijo debería dar"). La latencia real del pipeline es
**1 ciclo** (todo el producto-acumulado-saturado es combinacional, un
solo registro de historia a la entrada y uno a la salida) — si se toca
el RTL y hay que regenerar los vectores, el script Python usado para
generarlos está descrito en el README (sección de la Etapa 4b).

## Verificar que un build salió bien

- El bitstream queda en `prj/stream_app/out/red_pitaya.bit`.
- En la salida de Vivado, buscar `Bitgen Completed Successfully` y
  `0 Errors`.
- Chequeo automático de warnings/timing: `./synCheck.sh` (genera
  `synReport.txt-N`, no versionado). **Bug conocido**: el script tiene
  hardcodeado `FILEPATH="prj/v0.94/out/"` — no respeta `$(PRJ)`. Si
  compilaste `stream_app` (o cualquier otro proyecto que no sea
  `v0.94`), los 3 `ERROR: file ... not found` al final del reporte son
  falsos negativos de ese bug, no un problema real del build. Sí es
  información real el conteo de `CRITICAL WARNING:` que reporta (busca
  ese texto directo en `vivado.log`, sin depender de `$(PRJ)`) — sirve
  como referencia para comparar antes/después de agregar RTL propio.

## Variables de `make` que importan

- `PRJ` — nombre del proyecto. Para este trabajo, siempre `stream_app`.
- `MODEL` — placa de destino. `Z10` es la Zynq 7010 de la STEMlab 125-14
  (la que usa Sand Monitoring). El default del Makefile es `Z20_G2`
  (otra placa) — **hay que pasarlo siempre a mano**, no confiar en el
  default.

## Agregar un archivo `.v`/`.sv` NUEVO dentro de `ip/rp_oscilloscope/`

No alcanza con crear el archivo — esa carpeta es un IP empaquetado por
Vivado (formato IP-XACT: `component.xml`). Un archivo nuevo que no esté
listado ahí da `ERROR: [Synth 8-439] module '<nombre>' not found`
durante la síntesis, aunque el archivo exista y esté bien escrito.

Hay que agregarlo a mano en **los dos filesets** de `component.xml`
(síntesis y simulación — son dos bloques casi idénticos en el archivo),
con una entrada como esta (mismo patrón que las demás):
```xml
<spirit:file>
  <spirit:name>mi_modulo_nuevo.v</spirit:name>
  <spirit:fileType>verilogSource</spirit:fileType>
</spirit:file>
```
Para SystemVerilog (`.sv`) el `fileType` es `systemVerilogSource`. Si el
archivo vive fuera de `ip/rp_oscilloscope/` (por ejemplo en `rtl/`), el
`name` lleva la ruta relativa completa (ver las entradas existentes de
`axi4_if.sv`/`axi4_slave.sv` como ejemplo).

Modificar un archivo que YA está en esa lista (como se hizo en la Etapa
2 con `osc_top.v`, `rp_oscilloscope.v`, `scope_cfg.sv`) no necesita
tocar `component.xml` — esto solo aplica a archivos completamente
nuevos.

## Cosas que van a sorprender si no se saben de antemano

- **Cada build modifica archivos binarios ya versionados en git**
  (`out/*.dcp`, `out/*.bit`, `sdk/*.hwdef`, `sdk/*.sysdef`) aunque no
  hayas cambiado ni una línea de RTL — Vivado no genera bitstreams
  idénticos bit a bit entre corridas. Es normal ver esos archivos como
  modificados en `git status` después de cualquier build.
- `.gitignore` ya excluye lo que Vivado regenera solo y no aporta nada
  versionado (`.srcs/`, `.Xil/`, logs de Vivado, reportes de
  `synCheck.sh`) — no hace falta limpiarlos a mano.
