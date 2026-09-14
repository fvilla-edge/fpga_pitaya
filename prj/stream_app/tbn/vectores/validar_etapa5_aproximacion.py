#!/usr/bin/env python3
"""Etapa 5 (RedPitaya-FPGA): valida, ANTES de escribir RTL, la aproximacion
que el plan de la Etapa 5 (memoria del proyecto Sand Monitoring, sec.173)
da por buena: que un acumulador de area/kurtosis en HW puede asumir que la
media de cada ventana ya es ~0 (post-pasabanda) en vez de restar la media
EXACTA de la ventana como hace hoy el software (`analisis/placa/
area_kurtosis.py::_kurtosis_por_ventana`) - esto ultimo necesita ver la
ventana completa antes de poder calcular nada (dos pasadas), algo que un
acumulador de un solo streaming (una pasada) no puede hacer.

Usa el archivo real de referencia del proyecto
(datos_campo/42_1_reposo_20260903_145033_mono_dec32) pasado por el MISMO
modelo de punto fijo del filtro ya validado en la Etapa 4c/6 (bit exacto
con el RTL) - primera vez que se puede hacer esta comparacion con un
punto real, porque el filtro ahora vive despues del decimador, mismo
dominio de frecuencia/muestreo que ve el software.

Requiere el venv de este repo (numpy/scipy) + el repo Sand Monitoring
disponible en el path por defecto (~/Sand Monitoring).
"""
import sys
from pathlib import Path

import numpy as np

SAND_MONITORING = Path.home() / "Sand Monitoring"
sys.path.insert(0, str(SAND_MONITORING / "analisis"))
from revisar import _leer_canales_bin  # noqa: E402

ARCHIVO = SAND_MONITORING / "datos_campo" / "42_1_reposo_20260903_145033_mono_dec32" / "campo_reposo_20260903_145033_0001.bin"

FS = 3_906_250.0
VENTANA_S = 0.050
FRAC_BITS = 20
KURT_UMBRAL = 6.0

# mismos coeficientes cuantizados que bandpass_filter.v (Etapa 4c/6, default)
SECTIONS_Q = [
    (58743, 117487, 58743, -1311029, 526845),
    (1048576, -2097152, 1048576, -1984139, 943367),
]
ROUND_BIAS = 1 << (FRAC_BITS - 1)


def sat16(v):
    return max(-32768, min(32767, v))


def biquad_section_np(xs, B0, B1, B2, A1, A2):
    """Version vectorizada NO es posible (IIR con feedback, dependencia
    secuencial) - loop puro en Python, mismo modelo exacto que
    generar_etapa4c.py. Mas lento pero exacto; el archivo real tiene
    muchas muestras asi que esto puede tardar unos minutos."""
    n = len(xs)
    out = np.empty(n, dtype=np.int32)
    x1 = x2 = 0
    y1 = y2 = 0
    xs_list = xs.tolist()  # acceso a lista de Python es mucho mas rapido que numpy escalar en un loop
    for i in range(n):
        x0 = xs_list[i]
        acc = B0 * x0 + B1 * x1 + B2 * x2 - A1 * y1 - A2 * y2
        y0 = sat16((acc + ROUND_BIAS) >> FRAC_BITS)
        out[i] = y0
        x2, x1 = x1, x0
        y2, y1 = y1, y0
    return out


def cascade_fixed(xs):
    mid = biquad_section_np(xs, *SECTIONS_Q[0])
    return biquad_section_np(mid, *SECTIONS_Q[1])


# El archivo real completo son ~29s (~114M muestras) - el filtro IIR es
# secuencial (no vectorizable), un loop puro en Python sobre eso tardaria
# demasiado para una validacion rapida. 8s (~1250 ventanas de 50ms) ya es
# mas que suficiente para una comparacion estadistica solida - se puede
# subir este limite despues si hace falta mas certeza.
LIMITE_S = 8.0

print(f"Leyendo {ARCHIVO} ...")
ch0, ch1, meta = _leer_canales_bin(ARCHIVO)
print(f"Muestras totales en el archivo: {len(ch0)} ({len(ch0)/FS:.1f}s a fs={FS}Hz)")
n_limite = int(LIMITE_S * FS)
ch0 = ch0[:n_limite]
print(f"Usando los primeros {LIMITE_S}s ({len(ch0)} muestras) para esta validacion.")

print("Filtrando con el modelo de punto fijo (puede tardar unos minutos, es un IIR secuencial)...")
filtrado = cascade_fixed(ch0.astype(np.int64))
print("Filtrado listo.")

n_ventana = int(FS * VENTANA_S)
n_total = len(filtrado) // n_ventana
mat = filtrado[: n_total * n_ventana].reshape(n_total, n_ventana).astype(np.float64)

# --- Kurtosis EXACTA (como hoy el software: resta la media real de la ventana) ---
mat_exacta = mat - mat.mean(axis=1, keepdims=True)
m2_exacta = np.mean(mat_exacta ** 2, axis=1)
m4_exacta = np.mean(mat_exacta ** 4, axis=1)
kurt_exacta = m4_exacta / np.where(m2_exacta > 0, m2_exacta ** 2, 1e-30)

# --- Kurtosis APROXIMADA (como haria el acumulador en HW: asume media=0) ---
m2_aprox = np.mean(mat ** 2, axis=1)
m4_aprox = np.mean(mat ** 4, axis=1)
kurt_aprox = m4_aprox / np.where(m2_aprox > 0, m2_aprox ** 2, 1e-30)

clasif_exacta = kurt_exacta >= KURT_UMBRAL
clasif_aprox = kurt_aprox >= KURT_UMBRAL
coincide = clasif_exacta == clasif_aprox

medias = mat.mean(axis=1)
print(f"\nVentanas analizadas: {n_total}")
print(f"Media dentro de la ventana (post-filtro) - debería ser ~0 si la aproximacion vale:")
print(f"  media de |media_ventana|: {np.mean(np.abs(medias)):.4f}")
print(f"  max |media_ventana|:      {np.max(np.abs(medias)):.4f}")
print(f"  (referencia: la señal en si tiene std ~{np.std(filtrado):.1f})")

print(f"\nClasificacion (kurtosis >= {KURT_UMBRAL}):")
print(f"  coincidencia exacta vs aproximada: {coincide.sum()}/{n_total} ({100*coincide.mean():.2f}%)")
if not coincide.all():
    n_discrepan = (~coincide).sum()
    print(f"  {n_discrepan} ventanas discrepan - ejemplos (indice, kurt_exacta, kurt_aprox):")
    idx_disc = np.where(~coincide)[0][:10]
    for i in idx_disc:
        print(f"    ventana {i}: exacta={kurt_exacta[i]:.2f} aprox={kurt_aprox[i]:.2f}")

print(f"\nDiferencia relativa de kurtosis (exacta vs aproximada), percentiles:")
diff_rel = np.abs(kurt_aprox - kurt_exacta) / np.where(kurt_exacta > 0, kurt_exacta, 1e-30)
for p in (50, 90, 99, 100):
    print(f"  p{p}: {np.percentile(diff_rel, p)*100:.3f}%")
