#!/usr/bin/env python3
"""Segundo juego de coeficientes del pasabanda (Etapa 6 / limitacion de
decimacion): mismo diseño exacto que generar_etapa4c.py (Butterworth
orden 2, banda 50-400kHz, 25 bits, FRAC_BITS=20) pero para
fs=1953125Hz (dec64) en vez de 3906250Hz (dec32) - el hardware ya
soporta escribir estos por registro (Etapa 6), no hace falta un
bitstream nuevo. Reusa el MISMO modelo de punto fijo bit-exacto (no
reimplementado) para el chequeo de limit-cycle y de respuesta en
frecuencia, igual rigor que la Etapa 4c original.
"""
import numpy as np
from scipy.signal import butter, sosfreqz

FS = 1_953_125.0  # dec64
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

print(f"Coeficientes cuantizados para dec64 (fs={FS:.0f}Hz), Q{FRAC_BITS}, {COEFF_BITS} bits:")
nombres = ["b0_s0", "b1_s0", "b2_s0", "a1_s0", "a2_s0", "b0_s1", "b1_s1", "b2_s1", "a1_s1", "a2_s1"]
valores = list(sections_q[0]) + list(sections_q[1])
for nombre, v in zip(nombres, valores):
    signo = "-" if v < 0 else ""
    print(f"  cfg_bp_coeff_{nombre:6s} = {signo}25'sd{abs(v)}")

ROUND_BIAS = 1 << (FRAC_BITS - 1)


def sat16(v):
    return max(-32768, min(32767, v))


def biquad_section(xs, B0, B1, B2, A1, A2):
    x1 = x2 = 0
    y1 = y2 = 0
    out = []
    for x0 in xs:
        acc = B0 * x0 + B1 * x1 + B2 * x2 - A1 * y1 - A2 * y2
        y0 = sat16((acc + ROUND_BIAS) >> FRAC_BITS)
        out.append(y0)
        x2, x1 = x1, x0
        y2, y1 = y1, y0
    return out


def cascade_fixed(xs):
    mid = biquad_section(xs, *sections_q[0])
    return biquad_section(mid, *sections_q[1])


impulso = [30000] + [0] * 5000
salida_impulso = cascade_fixed(impulso)
cola = salida_impulso[-500:]
max_cola = max(abs(v) for v in cola)
print(f"\nChequeo de limit-cycle (impulso + silencio): max|salida| en la cola = {max_cola} "
      f"({20*np.log10(max_cola/32768+1e-12):.1f}dBFS) -> "
      f"{'residual chico, aceptable' if max_cola < 200 else 'ATENCION: residual grande'}.")

w, h_ideal = sosfreqz(sos, worN=8192, fs=FS)


def ideal_gain_db(freq_hz):
    idx = np.argmin(np.abs(w - freq_hz))
    return 20 * np.log10(max(abs(h_ideal[idx]), 1e-12))


test_freqs = [5_000, 50_000, 141_421, 400_000, 800_000]
amplitude = 10000
n_periods_settle = 30
n_periods_measure = 20
silencio_entre_tonos = 200

full_input = []
tone_ranges = []
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

print("\nRespuesta en frecuencia (fixed-point vs ideal), dec64:")
for f, (start, length) in zip(test_freqs, tone_ranges):
    x_measure = np.array(full_input[start:start + length], dtype=float)
    y_measure = np.array(full_expected[start:start + length], dtype=float)
    gain_measured_db = 20 * np.log10(np.std(y_measure) / np.std(x_measure) + 1e-12)
    gain_ideal_db = ideal_gain_db(f)
    print(f"  f={f:>9.0f}Hz  ideal={gain_ideal_db:7.2f}dB  medida(fixed-point)={gain_measured_db:7.2f}dB  "
          f"diff={abs(gain_ideal_db - gain_measured_db):.2f}dB")
