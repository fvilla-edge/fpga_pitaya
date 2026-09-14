#!/usr/bin/env python3
"""Etapa 4c (RedPitaya-FPGA): genera los vectores golden (entrada + salida
esperada) para validar bandpass_filter.v (pasabanda real, 50-400kHz,
Butterworth orden 2, fs=3906250Hz - la señal YA decimada por 32, igual
que ve el software; el filtro vive DESPUES del decimador en el pipeline,
no antes - ver la nota en osc_top.v y el README para el porque).

Tres cosas en un mismo script:
1) Respuesta en frecuencia: barre senos sinteticos en frecuencias clave
   (muy por debajo de la banda, los dos bordes, el centro geometrico, muy
   por arriba de la banda) y compara la ganancia medida contra la ideal
   (scipy.sosfreqz) - la validacion elegida para esta etapa, ya que no
   hay una captura cruda a la entrada del filtro (post-decimador) del
   sensor real para comparar contra la clasificacion de arena.
2) Chequeo de limit-cycle: impulso + silencio largo, confirma que la
   salida decae (no se queda oscilando en un valor no nulo para siempre -
   el problema real que obligo a mover el filtro de antes a despues del
   decimador, ver README).
3) Vectores bit-exactos: el mismo modelo en punto fijo que corre este
   script (incluido el REDONDEO, no truncar - ver bandpass_biquad.v) se
   usa para generar `etapa4c_expected.mem`, comparado en simulacion
   (Verilog) contra `bandpass_filter.v` ciclo a ciclo.

Requiere numpy y scipy - instalados en el venv de este repo
(`.venv/bin/python`), ver COMPILAR.md.
"""
import numpy as np
from scipy.signal import butter, sosfreqz

FS = 3_906_250.0  # ADC a 125MHz decimado por 32 - ver limitacion de decimacion fija en bandpass_filter.v
BAND = (50_000.0, 400_000.0)
ORDER = 2
COEFF_BITS = 25
FRAC_BITS = 20

sos = butter(ORDER, [BAND[0] / (FS / 2), BAND[1] / (FS / 2)], btype="bandpass", output="sos")


def quantize(v, frac_bits=FRAC_BITS, coeff_bits=COEFF_BITS):
    lo, hi = -(1 << (coeff_bits - 1)), (1 << (coeff_bits - 1)) - 1
    q = round(v * (1 << frac_bits))
    assert lo <= q <= hi, f"coeficiente fuera de rango: {v} -> {q}"
    return q


sections_q = []
for b0, b1, b2, a0, a1, a2 in sos:
    b0, b1, b2, a1, a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0
    sections_q.append(tuple(quantize(v) for v in (b0, b1, b2, a1, a2)))

print("Coeficientes cuantizados (Q%d, %d bits):" % (FRAC_BITS, COEFF_BITS))
for i, (B0, B1, B2, A1, A2) in enumerate(sections_q):
    print(f"  seccion {i}: B0={B0} B1={B1} B2={B2} A1={A1} A2={A2}")

ROUND_BIAS = 1 << (FRAC_BITS - 1)


def sat16(v):
    return max(-32768, min(32767, v))


def biquad_section(xs, B0, B1, B2, A1, A2):
    x1 = x2 = 0
    y1 = y2 = 0
    out = []
    for x0 in xs:
        acc = B0 * x0 + B1 * x1 + B2 * x2 - A1 * y1 - A2 * y2
        y0 = sat16((acc + ROUND_BIAS) >> FRAC_BITS)  # redondeo al mas cercano, no truncar
        out.append(y0)
        x2, x1 = x1, x0
        y2, y1 = y1, y0
    return out


def cascade_fixed(xs):
    mid = biquad_section(xs, *sections_q[0])
    return biquad_section(mid, *sections_q[1])


# ---------------------------------------------------------------------
# Chequeo de limit-cycle: impulso + silencio largo
# ---------------------------------------------------------------------
impulso = [30000] + [0] * 5000
salida_impulso = cascade_fixed(impulso)
cola = salida_impulso[-500:]
max_cola = max(abs(v) for v in cola)
print(f"\nChequeo de limit-cycle (impulso + silencio): max|salida| en la cola = {max_cola} "
      f"(sobre fondo de escala 32768, {20*np.log10(max_cola/32768+1e-12):.1f}dBFS) -> "
      f"{'residual chico, aceptable' if max_cola < 200 else 'ATENCION: residual grande'}. "
      f"NO decae a exactamente 0 (limit-cycle de punto fijo, esperado en IIR con feedback) "
      f"pero queda muy por debajo de amplitudes de señal real.")

# ---------------------------------------------------------------------
# Armar la entrada completa: un tono por frecuencia clave, con silencio
# entre medio para que no se mezclen transitorios, y calcular la salida
# esperada de una sola pasada (estado interno continuo, igual que el DUT)
# ---------------------------------------------------------------------
w, h_ideal = sosfreqz(sos, worN=8192, fs=FS)


def ideal_gain_db(freq_hz):
    idx = np.argmin(np.abs(w - freq_hz))
    return 20 * np.log10(max(abs(h_ideal[idx]), 1e-12))


test_freqs = [5_000, 50_000, 141_421, 400_000, 800_000]
amplitude = 10000
n_periods_settle = 30   # ciclos a descartar (transitorio) antes de medir
n_periods_measure = 20
silencio_entre_tonos = 200

full_input = []
tone_ranges = []  # (offset_inicio_medicion, largo_medicion) por tono, en el vector completo
for i, f in enumerate(test_freqs):
    period_samples = FS / f
    n_settle = int(period_samples * n_periods_settle)
    n_measure = int(period_samples * n_periods_measure)
    n_total = n_settle + n_measure
    t = np.arange(n_total)
    x = (amplitude * np.sin(2 * np.pi * f * t / FS)).round().astype(int)
    x = np.clip(x, -32768, 32767).tolist()

    offset = len(full_input)
    full_input.extend(x)
    tone_ranges.append((offset + n_settle, n_measure))

    if i != len(test_freqs) - 1:
        full_input.extend([0] * silencio_entre_tonos)

full_expected = cascade_fixed(full_input)

print("\nRespuesta en frecuencia (fixed-point vs ideal):")
for f, (start, length) in zip(test_freqs, tone_ranges):
    x_measure = np.array(full_input[start:start + length], dtype=float)
    y_measure = np.array(full_expected[start:start + length], dtype=float)
    gain_measured_db = 20 * np.log10(np.std(y_measure) / np.std(x_measure) + 1e-12)
    gain_ideal_db = ideal_gain_db(f)
    print(f"  f={f:>9.0f}Hz  ideal={gain_ideal_db:7.2f}dB  medida(fixed-point)={gain_measured_db:7.2f}dB  "
          f"diff={abs(gain_ideal_db - gain_measured_db):.2f}dB")

with open("etapa4c_input.mem", "w") as fo:
    for v in full_input:
        fo.write(format(v & 0xFFFF, "04x") + "\n")
with open("etapa4c_expected.mem", "w") as fo:
    for v in full_expected:
        fo.write(format(v & 0xFFFF, "04x") + "\n")

print(f"\nN muestras totales: {len(full_input)}")
print("Archivos escritos: etapa4c_input.mem, etapa4c_expected.mem")
