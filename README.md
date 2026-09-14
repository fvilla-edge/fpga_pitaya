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

- [x] **Etapa 0 — Git.** `git init` + commit inicial de todo tal cual está
      (incluye el build ya hecho de `stream_app`). No cambia nada
      funcional, da una base para poder volver atrás. **Hecho
      (2026-09-14):** repo respaldado en GitHub (`fpga_pitaya`, privado),
      con `.gitignore` excluyendo `.srcs`/`.Xil`/logs regenerables
      (`.git` bajó de ~373MB a 59MB sin perder nada necesario).
- [x] **Etapa 1 — Confirmar el toolchain, sin tocar RTL.** Recompilar
      `stream_app` tal cual está (sin ningún cambio propio) con el
      Makefile del repo, medir cuánto tarda un build completo. Prueba que
      Vivado+licencia+proyecto andan juntos de punta a punta en esta
      máquina, y da una idea real del ciclo de iteración. **Hecho
      (2026-09-14):** `make PRJ=stream_app clean` + rebuild del bitstream
      (`make PRJ=stream_app MODEL=Z10 prj/stream_app/out/red_pitaya.bit`)
      desde cero. Tiempo real: **5m08s** (`user` 7m57s con 8 hilos).
      `Bitgen Completed Successfully`, DRC con 0 errores. No se
      recompilaron FSBL/device-tree (`$(FSBL_ELF)`/`$(DEVICE_TREE)`) —
      requieren `xsct`/`hsi` (Vitis/SDK), que no están instalados en esta
      máquina; no hacen falta para iterar sobre el filtro, solo para
      generar la imagen de boot completa. **Nota:** `synCheck.sh` tiene
      `FILEPATH="prj/v0.94/out/"` hardcodeado (no respeta `$(PRJ)`) — los
      3 `ERROR: file ... not found` que tira al final son falsos
      negativos de ese bug preexistente del script, no un problema del
      build de `stream_app`. Sí es un dato real: detectó **50
      `CRITICAL WARNING:`** en todo el flujo (grep sobre `vivado.log`,
      no relacionado a `$(PRJ)`) — esto es el baseline del diseño sin
      tocar, útil como punto de comparación cuando se agregue RTL propio
      (Etapa 2 en adelante): si ese número sube después de nuestros
      cambios, es señal de mirar más de cerca.
- [x] **Etapa 2 — "Hola mundo" en RTL.** Agregar un módulo trivial y sin
      riesgo (un contador simple) leíble por un registro AXI nuevo, sin
      tocar nada existente. No hace nada útil todavía — el objetivo es
      probar que se puede agregar HDL nuevo, que compile, y que se pueda
      leer desde afuera por el mismo mecanismo de registros que va a usar
      el filtro real, sin romper el build existente. **Hecho
      (2026-09-14):** contador libre de 32 bits (`holamundo_cnt`,
      incrementa cada ciclo de `clk_adc`, sin conexión a ninguna lógica
      existente) agregado en `ip/rp_oscilloscope/osc_top.v`, expuesto
      como registro nuevo `DIAG_REG5` (offset `0xF0`, el primer hueco
      libre después de los diagnósticos existentes `0xE0-0xEC`) en
      `scope_cfg.sv`, siguiendo el mismo patrón que los diagnósticos ya
      existentes (`diag1_o..diag4_o`) — mismos 3 archivos tocados
      (`osc_top.v`, `rp_oscilloscope.v`, `scope_cfg.sv`), ningún puerto
      ni lógica existente modificados, solo agregados.
      Validado por ahora solo con rebuild limpio (sin simulación
      todavía): `Bitgen Completed Successfully`, DRC 0 errores. El
      primer intento agregó un warning de estilo nuevo (`holamundo_cnt`
      usado antes de su declaración) — corregido reordenando el
      `reg`/`always` antes del `assign`. **Hallazgo metodológico:** el
      conteo de warnings de DRC varía ±1 entre builds con el MISMO RTL
      (comparado build a build: la diferencia fue un warning de
      pipelining de DSP en `rp_dac`, un módulo que no tocamos) — Vivado
      no es determinista al 100% entre corridas. Conclusión: un conteo
      de warnings que sube o baja en 1 no es señal confiable de que un
      cambio de RTL rompió algo; hay que buscar el nombre de la señal/
      módulo propio en el log, no solo mirar el número agregado.
      **Actualización (misma sesión, más tarde): validado en simulación.**
      `make sim` resultó no servir para esto (ver sección "Simulación:
      estado y plan" más abajo) — se armó en cambio un testbench propio,
      standalone, con las herramientas de línea de comandos de Vivado
      (`xvlog`/`xelab`/`xsim`, sin project/IP-integrator, sin GUI):
      `prj/stream_app/tbn/tb_scope_cfg_diag5.sv` + `etapa2_sim_diag5.sh`.
      Instancia SOLO `scope_cfg.sv` (el decodificador de registros AXI),
      no `rp_oscilloscope.v` completo (motivo: depende de un core Xilinx
      FIFO Generator vía catálogo de IP, que no compila standalone sin
      generar antes esa IP en un proyecto — ver plan de simulación).
      7/7 checks OK: los 4 diagnósticos existentes (`DIAG_REG1-4`) siguen
      leyéndose bien, `DIAG_REG5` (0xF0) lee el valor correcto, sigue el
      valor en vivo tras cambiarlo, y la dirección siguiente sin mapear
      (0xF4) no alias-ea con él. **Lo que esto prueba:** el decodificador
      de direcciones (la parte de más riesgo, tipeada a mano) está bien.
      **Lo que esto NO prueba todavía:** que el contador de `osc_top.v` y
      el cableado de 4 canales en `rp_oscilloscope.v` lleguen bien hasta
      ahí (siguen sin simular) — pendiente real, ver plan de simulación.
- [x] **Etapa 3 — Filtro como "pasamanos" (bypass).** Insertar el bloque
      del filtro en el lugar real del pipeline (antes de `osc_decimator`,
      junto a `osc_filter`), configurado para no filtrar nada (pasar la
      señal tal cual). Validar en **simulación** que los datos salen
      exactamente iguales que sin el bloque — prueba que encaja en el
      lugar correcto sin romper el flujo de datos. **Hecho
      (2026-09-14):** el lugar real NO es "junto a `osc_filter`" como
      decía el plan original — `osc_filter` corre sobre la señal SIN
      calibrar, y el software siempre filtra sobre la señal ya calibrada.
      Se insertó en cambio **después de `osc_calib` y antes del mux del
      decimador**, misma señal que ve hoy el software. Módulo nuevo
      `ip/rp_oscilloscope/bandpass_biquad.v` — por ahora puro pasamanos
      combinacional (`assign`, sin registros, sin `cfg_bypass`; el
      control por registro se agrega recién en la Etapa 4a, decisión
      explícita del usuario para no sumar superficie antes de tiempo).
      Validado en dos niveles: simulación standalone
      (`etapa3_sim_bandpass.sh` + `tbn/tb_bandpass_biquad_passthrough.sv`,
      200/200 checks con datos/valid/ready aleatorios — transparente en
      todos los casos) y rebuild completo del bitstream
      (`Bitgen Completed Successfully`, DRC 0 errores, mismo baseline de
      warnings que la Etapa 2). **Gotcha real encontrado:** un archivo
      `.v` nuevo en `ip/rp_oscilloscope/` NO alcanza con crearlo — esa
      carpeta es un IP empaquetado por Vivado (formato IP-XACT,
      `component.xml`) y hay que agregar el archivo a mano en la lista
      de fuentes de `component.xml` (dos filesets: síntesis y
      simulación) o el synth falla con
      `module 'bandpass_biquad' not found`. Ya resuelto para este
      archivo; va a volver a aparecer si la Etapa 4 agrega más archivos
      nuevos al mismo IP — anotado en `COMPILAR.md`.
- **Etapa 4 — Filtro real, biquad Direct Form I.** `osc_filter.v` NO es
      reusable tal cual (ver "Estudio del filtro existente" más abajo) —
      hace falta escribir un módulo biquad nuevo. Para no saltar directo
      del bypass (Etapa 3) a los coeficientes reales, se divide en
      sub-pasos chicos, cada uno aislando un tipo de error distinto antes
      de sumar el siguiente (idea del usuario, sesión 2026-09-14: "ir
      probando de a poco" aplicado a la integración del módulo, no a la
      forma matemática del filtro — un pasabanda resonante necesita sí o
      sí un par de polos complejos conjugados, no hay versión más
      "simple" de la topología que siga sirviendo para el objetivo):
  - [ ] **Etapa 4a — Biquad con coeficientes triviales.** `b0` = ganancia
        unitaria, `b1=b2=a1=a2=0`. Validar en simulación que da
        exactamente lo mismo que el bypass de la Etapa 3. Prueba que el
        camino de datos del módulo nuevo (anchos de bit, saturación,
        timing) no tiene bugs de plomería, sin meter todavía complejidad
        numérica real.
  - [ ] **Etapa 4b — Biquad con coeficientes simples conocidos.** Un
        pasabajos de juguete, fácil de verificar a mano. Validar contra
        `scipy.signal.lfilter` con esos mismos coeficientes (bit a bit o
        con tolerancia chica). Prueba que la aritmética de punto fijo del
        biquad es correcta en general, con un caso simple.
  - [ ] **Etapa 4c — Biquad con los coeficientes reales.** Mismos
        coeficientes que ya se validaron en software (`analisis/placa/`
        de Sand Monitoring, commit `e979c5c`). Validar en simulación
        contra el mismo archivo real usado en esa validación de software
        (`datos_campo/42_1_reposo_20260903_145033` en el repo Sand
        Monitoring), mismo criterio ya usado en todo el proyecto: no
        exigir igualdad numérica exacta, sí que la clasificación de
        arena (kurtosis>=6 por ventana) coincida.

## Estudio del filtro existente (2026-09-14)

Antes de escribir cualquier RTL nuevo, se leyó `osc_filter.v` completo
(el filtro IIR configurable que el plan original asumía como plantilla
directamente reutilizable) para entender su topología real.

**Hallazgo: `osc_filter.v` no es un biquad de propósito general.**
Rastreando la lógica (líneas 99-184 del archivo), la estructura es:

- Una etapa tipo diferenciador/cero con `coeff_bb` (combina `din` crudo
  y `din*bb` con un delay).
- **IIR 1**: un único polo real por realimentación con `coeff_aa`
  (`y[n] ≈ x[n]·K + y[n-1]·(1 − aa/2²⁵)`).
- **IIR 2**: otro único polo real, independiente, con `coeff_pp`.
- Escalado + saturación con `coeff_kk`.

Son **dos polos reales en cascada, no un par de polos complejos
conjugados**. Esto es coherente con su uso real en Red Pitaya: un filtro
de compensación/shelving para corregir la respuesta del front-end
analógico, no un pasabanda resonante. El pasabanda Butterworth orden 2
ya validado en software (ver `analisis/placa/` de Sand Monitoring)
necesita un par de polos complejos — la forma estándar es un biquad
Direct Form (`b0,b1,b2,a1,a2`, con términos `x[n-2]`/`y[n-2]`), que esta
estructura no tiene. **Conclusión: hace falta escribir un módulo nuevo,
no reconfigurar este.** Lo que sí es reusable de `osc_filter.v` es el
patrón de pipeline en punto fijo (anchos de bit trackeados a mano por
etapa, `(* use_dsp="yes" *)` en los registros que deben mapear a DSP48,
saturación final) — no la topología matemática.

**Qué forma de biquad usar (Direct Form I, no Direct Form II
Transposed):** para punto fijo en hardware, Direct Form I es la opción
más segura. Confirmado indirectamente: la librería CMSIS-DSP de ARM solo
ofrece su biquad "Direct Form II Transposed" en punto flotante — la
documentación es explícita en que esa forma requiere rango dinámico
amplio en las variables de estado internas, mientras que sus biquads en
punto fijo (Q15/Q31) usan Direct Form I. La razón de fondo: en Direct
Form I los registros de retardo guardan directamente muestras de entrada
y salida pasadas (`x[n-1]`, `x[n-2]`, `y[n-1]`, `y[n-2]`), con rango
acotado y conocido de antemano; en Direct Form II/Transposed el estado
interno compartido puede crecer mucho más que la entrada o la salida
(especialmente cerca de resonancia/alta Q), lo que obliga a guardar
margen extra para no desbordar. Esto además es coherente con el propio
`osc_filter.v`: sus dos secciones de un polo ya usan cadenas de
acumulación separadas por término (no un estado canónico compartido),
el mismo espíritu que Direct Form I.
(Fuentes: [documentación CMSIS-DSP sobre Biquad Cascade DF2T](https://arm-software.github.io/CMSIS-DSP/latest/group__BiquadCascadeDF2T.html);
comparación de estructuras de biquad en punto fijo discutida en
[comp.dsp — IIR biquad implementation in fixed point/integer](https://www.dsprelated.com/showthread/comp.dsp/220284-1.php).)

**Dato de hardware confirmado — DSP48E1 (Zynq 7010, 7-series):**
multiplicador asimétrico 25×18 bits con dos puertos de entrada de ancho
distinto. Esto explica por qué `osc_filter.v` usa `coeff_aa` de 18 bits
(registro `0xC0`, puerto estrecho del DSP48) y `coeff_bb`/`coeff_kk`/
`coeff_pp` de 24-25 bits (puerto ancho) — no es arbitrario, está pensado
para mapear un multiplicador por coeficiente a un único DSP48E1. Para el
biquad nuevo (5 coeficientes: `b0,b1,b2,a1,a2`) hay que decidir a
propósito qué coeficientes van en el puerto de 18 bits y cuáles en el de
25 — probablemente `a1,a2` (realimentación, más sensibles a precisión
cerca del círculo unitario) en el puerto ancho, y `b0,b1,b2` en el
estrecho, pero esto se valida numéricamente en simulación contra los
coeficientes reales de `analisis/placa/`, no se decide a priori.

**Pendiente todavía sin resolver, para cuando se escriba el módulo:**
el tracking exacto de crecimiento de bits por etapa (como hace
`osc_filter.v` en sus comentarios) y cuántos DSP48E1 hacen falta por
canal (mínimo 5 multiplicadores por biquad si no se time-multiplexa;
a 125 MSPS con margen de reloj interno podría compartirse menos DSP48
corriendo a mayor frecuencia — no evaluado todavía).
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

## Simulación: estado y plan (2026-09-14)

El plan original (sección de arriba) asumía que `make sim` ya andaba y
solo faltaba correrlo. **Resultó falso en dos niveles distintos**, ambos
confirmados corriendo los comandos, no solo leyendo código:

1. El target `sim` del Makefile invoca `vivado -source ...` **sin**
   `-mode batch` — está pensado para abrir la GUI de Vivado de forma
   interactiva, no para correr headless. En esta máquina se cuelga
   esperando una ventana.
2. Más de fondo: **no existe ningún `top_tb` para el proyecto
   `stream_app` en la placa Z10** — ese archivo solo existe para otras
   variantes del repo (`stream_app_4ch`, `stream_app_250`, `classic`,
   `v0.94`, etc.), nunca se escribió para esta combinación. Aunque se
   arreglara el modo batch, no habría qué correr.

Arreglar esto de punta a punta (para tener un entorno de simulación
completo del SoC, reusable para validar el filtro real de las Etapas 3
y 4 contra datos capturados reales) es un trabajo grande aparte. Para no
bloquear la Etapa 2 con eso, se armó un camino corto en paralelo. Las
dos cosas conviven, son etapas de una escalera, no alternativas:

- [x] **Simulación A — Unit test standalone de `scope_cfg.sv` (hecho
      2026-09-14).** Compila con `xvlog`/`xelab`/`xsim` (herramientas de
      línea de comandos que vienen con Vivado, sin project ni
      IP-integrator, sin GUI) SOLO el decodificador de registros AXI
      (`scope_cfg.sv`) + sus dependencias de RTL plano (`axi4_if.sv`,
      `sys_bus_if.sv`, `axi4_slave.sv`, `sync_rw_single.v`, todas en
      `rtl/`, sin IP de Xilinx) + el modelo de maestro AXI que ya existía
      en `tbn/axi_master_model.sv`. Testbench nuevo:
      `prj/stream_app/tbn/tb_scope_cfg_diag5.sv`, script:
      `etapa2_sim_diag5.sh` (`./etapa2_sim_diag5.sh`, tarda segundos, no
      minutos). Prueba el decodificador de direcciones con valores
      inventados en `diagN_i` — rápido y determinista, pero NO pasa por
      el contador real de `osc_top.v` ni por el cableado de canales de
      `rp_oscilloscope.v`.
- [ ] **Simulación B — Sumar `osc_top.v` al mismo testbench standalone.**
      En vez de alimentar `diag5_i` a mano, instanciar `osc_top.v`
      (verificar primero que no tiene ninguna dependencia de IP de
      Xilinx — a diferencia de `rp_oscilloscope.v`, no debería, ya que
      el core FIFO Generator lo usan los bloques de DMA que viven un
      nivel más arriba) y leer su `diag5_o` real. Prueba el contador +
      el `assign` en `osc_top.v`, sigue sin probar el cableado de 4
      canales en `rp_oscilloscope.v`.
- [ ] **Simulación C — Sumar `rp_oscilloscope.v` completo.** Acá sí
      aparece la dependencia real: sus bloques de DMA (`U_dma_s2mm`)
      instancian un core Xilinx FIFO Generator vía catálogo de IP, que
      no tiene un modelo de simulación como archivo de texto plano — hay
      que generarlo (`generate_target simulation` sobre un proyecto
      Vivado mínimo, no todo el block design) antes de poder compilarlo
      con `xvlog`. Alternativa más rápida a evaluar: un stub/mock de
      simulación de esos bloques de DMA si no son relevantes para lo que
      se esté probando (el filtro/contador no los toca).
- [ ] **Simulación D — Arreglar el flujo completo del SoC (`make sim`
      real).** Escribir el `top_tb` que falta para `stream_app`+Z10,
      usando `system_model.sv` (el modelo de comportamiento de la PS que
      ya está en `tbn/`, se usa en otras variantes del proyecto) y
      correrlo en modo batch (agregar `-mode batch` al target `sim` del
      Makefile, o un script aparte que no la toque). Esto es lo que hace
      falta para inyectar una captura real (de `datos_campo/` en Sand
      Monitoring) como estímulo de ADC y validar el filtro completo
      (Etapa 4c) contra el criterio real de clasificación, sin esperar a
      la placa nueva. Es la etapa más grande de las 4 — no arrancar sin
      confirmar antes que B y C ya dieron resultado.

**Cómo no perderse en esto:** cada simulación nueva se prueba SOLA
primero (correr el script, ver que compila y corre, revisar los
resultados) antes de sumarle la siguiente pieza — mismo espíritu que las
Etapas 4a/4b/4c del filtro. Si una pieza nueva no compila por una
dependencia de IP de Xilinx no resuelta, ese es exactamente el punto en
el que hay que decidir generar la IP o mockearla, no forzar un atajo.

## Referencias

- Memoria del proyecto Sand Monitoring, sec.169-174 (`~/Sand Monitoring`,
  no versionado acá — pedirle a Claude que la lea si hace falta contexto
  de por qué se llegó a este plan).
- `analisis/placa/` en `~/Sand Monitoring`: paquete de software (Python +
  C) que hace lo mismo que se quiere mover a HW — sirve de referencia de
  formulas/validación (rama `area-en-placa`, sin mergear a `main` a
  propósito).
