#!/usr/bin/env python3
"""Simulacion D (extension, muestreo mas amplio): extrae varias ventanas
reales de distintos archivos de datos/Dia miercoles 3 de Sept (mono,
dec32 - el mismo fs para el que estan calculados los coeficientes fijos
del pasabanda, ver limitacion de decimacion conocida en el README) para
ampliar la confianza de la Simulacion D mas alla de un solo par
evento/reposo.

Mismo criterio y formulas que extraer_datos_reales_simD.py - no
reimplementa, solo repite el procedimiento sobre mas archivos, eligiendo
a proposito diversidad de magnitud (evento fuerte, moderado, y reposo
cerca del umbral) en vez de repetir el mismo tipo de ventana.
"""
import json
import sys
from pathlib import Path

import numpy as np
from scipy.stats import kurtosis as scipy_kurtosis

SAND_MONITORING = Path("/home/facu-edge/Sand Monitoring")
sys.path.insert(0, str(SAND_MONITORING / "analisis"))
sys.path.insert(0, str(SAND_MONITORING / "analisis" / "placa"))
from revisar import _leer_canales_bin  # noqa: E402
from area_kurtosis import _filtrar_pasabanda, FILTRO_BANDA_HZ, FILTRO_ORDEN  # noqa: E402

FS = 3_906_250.0  # dec32 - el fs real del filtro fijo de HW
VENTANA_MUESTRAS = 195_312
FA_THRESH = 6

BASE = Path("/home/facu-edge/datos/Dia miercoles 3 de Sept/lote1_mono")

# (nombre de sesion, "max" = ventana de mayor kurtosis, "min" = de menor)
SELECCION = [
    ("42_1_reposo_20260903_144456_mono_dec32", "max", "evento_fuerte"),
    ("42_1_reposo_20260903_144128_mono_dec32", "max", "evento_moderado"),
    ("42_1_reposo_20260903_143859_mono_dec32", "max", "evento_moderado2"),
    ("42_1_reposo_20260903_143628_mono_dec32", "min", "reposo1"),
    ("42_1_reposo_20260903_143720_mono_dec32", "min", "reposo2"),
    ("42_1_reposo_20260903_145351_mono_dec32", "max", "reposo_cerca_umbral"),  # max de un archivo sin eventos = el mas cerca del umbral
]

OUT_DIR = Path(__file__).parent / "lote2_simD"
OUT_DIR.mkdir(exist_ok=True)


def area_kurtosis_ventana(x):
    x = x.astype(np.float64)
    n = len(x)
    sum_abs = np.sum(np.abs(x))
    sum_x2 = np.sum(x * x)
    sum_x4 = np.sum(x * x * x * x)
    m2 = sum_x2 / n
    m4 = sum_x4 / n
    kurt = (m4 / (m2 * m2)) if m2 > 0 else 0.0
    return dict(area=float(sum_abs / FS), kurtosis=float(kurt),
                sum_abs=int(round(sum_abs)), sum_x2=int(round(sum_x2)), sum_x4=int(round(sum_x4)))


def escribir_readmemh(muestras_int16, ruta):
    with open(ruta, "w") as f:
        for v in muestras_int16:
            f.write(f"{np.uint16(v):04x}\n")


def main():
    manifest = []
    for idx, (nombre_sesion, modo, etiqueta) in enumerate(SELECCION):
        archivo = next((BASE / nombre_sesion).glob("campo_*.bin"))
        print(f"[{idx}] {nombre_sesion} ({modo}, {etiqueta}) ...")
        ch0, ch1, meta = _leer_canales_bin(archivo)
        n_ventanas = len(ch0) // VENTANA_MUESTRAS

        mejor_k = None
        mejor_i = None
        for i in range(n_ventanas):
            seg = ch0[i*VENTANA_MUESTRAS:(i+1)*VENTANA_MUESTRAS].astype(np.float32)
            filt = _filtrar_pasabanda(seg, FS, banda=FILTRO_BANDA_HZ, orden=FILTRO_ORDEN)
            k = scipy_kurtosis(filt, fisher=False)
            if mejor_k is None or (modo == "max" and k > mejor_k) or (modo == "min" and k < mejor_k):
                mejor_k, mejor_i = k, i

        cruda = ch0[mejor_i*VENTANA_MUESTRAS:(mejor_i+1)*VENTANA_MUESTRAS]
        filtrada = _filtrar_pasabanda(cruda.astype(np.float32), FS, banda=FILTRO_BANDA_HZ, orden=FILTRO_ORDEN)
        ref = area_kurtosis_ventana(filtrada)
        ref.update(kurtosis_scipy=float(mejor_k), ventana_indice=mejor_i,
                   clasificacion="evento" if mejor_k >= FA_THRESH else "reposo",
                   archivo=nombre_sesion, etiqueta=etiqueta)

        escribir_readmemh(cruda, OUT_DIR / f"stimulus_{idx}.mem")
        with open(OUT_DIR / f"referencia_{idx}.json", "w") as f:
            json.dump(ref, f, indent=2)
        manifest.append(dict(idx=idx, etiqueta=etiqueta, archivo=nombre_sesion,
                              kurtosis_sw=float(mejor_k), clasificacion=ref["clasificacion"]))
        print(f"    ventana #{mejor_i}, kurtosis={mejor_k:.2f} -> {ref['clasificacion']}")

    with open(OUT_DIR / "manifest.json", "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"\n{len(manifest)} pares escritos en {OUT_DIR}")


if __name__ == "__main__":
    main()
