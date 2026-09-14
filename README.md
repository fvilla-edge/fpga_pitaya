# Plan: pasabanda de arena en la FPGA (Zynq 7010)

**Fecha:** 2026-09-11. Retomar desde acá — no se ejecutó nada todavía, es
solo el plan.

## Contexto

Proyecto "Sand Monitoring" (`~/Sand Monitoring`, repo git aparte de este):
sistema de detección acústica de arena en tuberías con un sensor sobre una
Red Pitaya STEMlab 125-14. El pipeline de detección (filtro pasabanda
50-400kHz + área/kurtosis por ventana de 50ms) hoy corre en software sobre
el ARM Cortex-A9 de la placa (Python y una reescritura en C) y no llega a
tiempo real ni optimizado (proyección actual: ~0.80x tiempo real,
combinando filtro causal + orden 2 — ver `Sand Monitoring`, memoria del
proyecto sec.169-174, o `analisis/placa/` en ese repo).

La idea de este plan: mover el filtro (y potencialmente el cálculo de
área/kurtosis) a la lógica programable del Zynq, que corre en paralelo al
ARM y no compite por CPU con la captura — en principio, tiempo real
genuino en vez de una optimización parcial. Esto es **alto esfuerzo/alto
riesgo** (nadie en el proyecto tiene experiencia previa en HDL) y se
prueba primero acá, en esta placa nueva de pruebas cuando llegue —
**nunca en la placa de campo** (freeze vigente, ver memoria del proyecto
sec.171).

## Lo que ya se confirmó (2026-09-11, sesión de investigación)

- **Vivado 2020.1 instalado y licenciado en esta máquina**
  (`/tools/Xilinx/Vivado/2020.1/bin/vivado`, licencia en `~/.Xilinx/`).
- **Ya existe un build completo y exitoso de `prj/stream_app`**
  (síntesis+place+route+bitstream en `prj/stream_app/out/`, fechado
  30/6/2026, hecho con esta misma versión de Vivado) — toolchain, proyecto
  y licencia ya se probaron juntos con éxito antes.
- `prj/stream_app` es el proyecto que genera el bitstream que usa el
  `streaming-server`/`rpsa_client` real en producción (no un ejemplo
  genérico).
- Registro de direcciones documentado en
  `prj/stream_app/regset_common_streaming.rst`: el bloque "ADC streaming
  (IN)" vive en `0x40000000-0x400FFFFF` — es el que usa `rpsa_client`,
  **no tocar/romper ese rango** al agregar registros nuevos.
- Ya existe un filtro IIR configurable en el pipeline de ADC, que sirve de
  plantilla de diseño: `prj/stream_app/ip/rp_oscilloscope/osc_filter.v`
  (pipeline AXI4-Stream limpio, coeficientes configurables por registro,
  con `cfg_bypass`). Hoy se usa para compensación analógica, no para
  detección de arena.
- Orden confirmado del pipeline en
  `prj/stream_app/ip/rp_oscilloscope/osc_top.v`: `osc_filter` (línea 226)
  corre **antes** que `osc_decimator` (línea 275) — el filtro nuevo
  probablemente va en ese mismo lugar, antes de decimar.
- Hay un core de debug ya disponible en el pool de IP compartido
  (`ip/ila_0`, Integrated Logic Analyzer de Xilinx) — útil para mirar
  señales internas una vez que haya placa real.
- Ya existe un flujo de simulación (`make sim`, ver
  `prj/stream_app/tbn/systemZ10_sim.tcl`) — permitiría validar el filtro
  nuevo contra datos reales (las mismas capturas usadas en el proyecto
  Sand Monitoring) **sin necesitar la placa física todavía**. No se corrió
  todavía, solo se confirmó que existe.
- **Esta carpeta NO está bajo control de versiones** (`git status` da "no
  es un repositorio git"). Hay que arreglar eso ANTES de tocar nada — es
  el primer paso del plan.

## Plan de etapas

Cada etapa prueba UNA cosa nueva antes de sumar la siguiente. Las etapas
0-4 se pueden hacer sin la placa nueva; de la 5 en adelante hace falta
tenerla.

- [ ] **Etapa 0 — Git.** `git init` + commit inicial de todo tal cual está
      (incluye el build ya hecho de `stream_app`). No cambia nada
      funcional, da una base para poder volver atrás.
- [ ] **Etapa 1 — Confirmar el toolchain, sin tocar RTL.** Recompilar
      `stream_app` tal cual está (sin ningún cambio propio) con el
      Makefile del repo, medir cuánto tarda un build completo. Prueba que
      Vivado+licencia+proyecto andan juntos de punta a punta en esta
      máquina, y da una idea real del ciclo de iteración.
- [ ] **Etapa 2 — "Hola mundo" en RTL.** Agregar un módulo trivial y sin
      riesgo (un contador simple) leíble por un registro AXI nuevo, sin
      tocar nada existente. No hace nada útil todavía — el objetivo es
      probar que se puede agregar HDL nuevo, que compile, y que se pueda
      leer desde afuera por el mismo mecanismo de registros que va a usar
      el filtro real, sin romper el build existente.
- [ ] **Etapa 3 — Filtro como "pasamanos" (bypass).** Insertar el bloque
      del filtro en el lugar real del pipeline (antes de `osc_decimator`,
      junto a `osc_filter`), configurado para no filtrar nada (pasar la
      señal tal cual). Validar en **simulación** que los datos salen
      exactamente iguales que sin el bloque — prueba que encaja en el
      lugar correcto sin romper el flujo de datos.
- [ ] **Etapa 4 — Filtro real, coeficientes fijos (orden 2).** Mismos
      coeficientes que ya se validaron en software (`analisis/placa/` de
      Sand Monitoring, commit `e979c5c`). Validar en simulación contra el
      mismo archivo real usado en esa validación de software
      (`datos_campo/42_1_reposo_20260903_145033` en el repo Sand
      Monitoring), mismo criterio: no exigir igualdad numérica exacta,
      sí que la clasificación de arena (kurtosis>=6 por ventana) coincida.
- [ ] **Etapa 5 (opcional, más ambiciosa) — Acumuladores de área/kurtosis
      en HW.** No solo el filtro: sumas de |x|, x² y x⁴ por ventana
      también son streameables (ver memoria del proyecto sec.173).
      Validar igual, en simulación, contra los mismos datos reales.
- [ ] **Etapa 6 — Coeficientes configurables por software**, igual que ya
      hace `osc_filter.v` (`cfg_coeff_*`, `cfg_bypass`) — para no
      recompilar el bitstream cada vez que se ajuste el filtro.
- [ ] **Etapa 7 — Primera prueba en la placa nueva, cuando llegue.**
      Primero confirmar que la captura/`rpsa_client` que YA funciona sigue
      andando igual con el bitstream nuevo, ANTES de mirar si el filtro
      nuevo da resultados correctos.
- [ ] **Etapa 8 — Validación con datos reales en la placa nueva**,
      comparando contra el pipeline de software (mismo criterio de
      coincidencia de clasificación usado en el resto del proyecto).

## Referencias

- Memoria del proyecto Sand Monitoring, sec.169-174 (`~/Sand Monitoring`,
  no versionado acá — pedirle a Claude que la lea si hace falta contexto
  de por qué se llegó a este plan).
- `analisis/placa/` en `~/Sand Monitoring`: paquete de software (Python +
  C) que hace lo mismo que se quiere mover a HW — sirve de referencia de
  formulas/validación (rama `area-en-placa`, sin mergear a `main` a
  propósito).
