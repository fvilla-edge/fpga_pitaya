#!/usr/bin/env python3
"""Simulacion D (dec64, para MOSTRAR el corrimiento de banda ya conocido,
no para "aprobar" nada): extrae ventanas reales de lote3_mono (dec64,
fs=1953125Hz real) y las corre contra el MISMO osc_top.v con los
coeficientes fijos calculados para dec32 (fs=3906250Hz) - a proposito,
sin recalcular nada, para ver el efecto de la limitacion ya documentada
en el README con datos reales en vez de solo en teoria.

La referencia de software SI usa el fs real (1953125Hz) - es la
correcta. El mismatch esperado entre HW y esa referencia es la
limitacion conocida mostrandose, no una falla nueva.
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

FS_REAL = 1_953_125.0  # dec64 - el fs VERDADERO de este dato
VENTANA_MUESTRAS = 97_656  # 50ms a fs=1953125Hz (mismo AREA_VENTANA_S=0.050s de siempre)
FA_THRESH = 6

BASE = Path("/home/facu-edge/datos/Dia miercoles 3 de Sept/lote3_mono")

SELECCION = [
    ("42_1_reposo_20260903_164703_mono_dec64", "max", "evento_fuerte_dec64"),
    ("42_1_reposo_20260903_164536_mono_dec64", "max", "evento_moderado_dec64"),
    ("42_1_reposo_20260903_164209_mono_dec64", "min", "reposo_dec64"),
]

OUT_DIR = Path(__file__).parent / "dec64_simD"
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
    return dict(area=float(sum_abs / FS_REAL), kurtosis=float(kurt))


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

        mejor_k, mejor_i = None, None
        for i in range(n_ventanas):
            seg = ch0[i*VENTANA_MUESTRAS:(i+1)*VENTANA_MUESTRAS].astype(np.float32)
            filt = _filtrar_pasabanda(seg, FS_REAL, banda=FILTRO_BANDA_HZ, orden=FILTRO_ORDEN)
            k = scipy_kurtosis(filt, fisher=False)
            if mejor_k is None or (modo == "max" and k > mejor_k) or (modo == "min" and k < mejor_k):
                mejor_k, mejor_i = k, i

        cruda = ch0[mejor_i*VENTANA_MUESTRAS:(mejor_i+1)*VENTANA_MUESTRAS]
        filtrada = _filtrar_pasabanda(cruda.astype(np.float32), FS_REAL, banda=FILTRO_BANDA_HZ, orden=FILTRO_ORDEN)
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
