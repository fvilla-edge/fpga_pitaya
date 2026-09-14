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

**Simulación** (target existe en el Makefile, **no probado todavía** en
este repo):
```
make PRJ=stream_app MODEL=Z10 sim
```

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

## Cosas que van a sorprender si no se saben de antemano

- **Cada build modifica archivos binarios ya versionados en git**
  (`out/*.dcp`, `out/*.bit`, `sdk/*.hwdef`, `sdk/*.sysdef`) aunque no
  hayas cambiado ni una línea de RTL — Vivado no genera bitstreams
  idénticos bit a bit entre corridas. Es normal ver esos archivos como
  modificados en `git status` después de cualquier build.
- `.gitignore` ya excluye lo que Vivado regenera solo y no aporta nada
  versionado (`.srcs/`, `.Xil/`, logs de Vivado, reportes de
  `synCheck.sh`) — no hace falta limpiarlos a mano.
