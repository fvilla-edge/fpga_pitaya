#!/usr/bin/env python3
"""Simulacion D (RedPitaya-FPGA): extrae de un archivo real de
datos_campo/ (Sand Monitoring) dos ventanas de AREA_VENTANA_S (50ms,
195312 muestras a fs=3906250Hz) - una clasificada como evento de arena
(kurtosis>=6) y una como reposo - para usarlas como estimulo real del
testbench SystemVerilog (tb_area_kurtosis_simD.sv), y calcula el area y
kurtosis de referencia con el MISMO codigo que usa el software real
(area_kurtosis.py de Sand Monitoring), no una reimplementacion.

No convierte a voltios a proposito: el area de referencia se calcula
sobre las muestras int16 crudas (mismo dominio que ve el hardware en
s_axis_tdata), no en voltios - kurtosis da igual en cualquier escala
(es una normalizacion de 4to momento / varianza^2), pero el area
(sum|x|) si escala, y hardware trabaja en cuentas ADC, no en voltios.

Requiere numpy/scipy - usar el venv de este repo: .venv/bin/python
"""
import sys
from pathlib import Path

import numpy as np
from scipy.stats import kurtosis as scipy_kurtosis

SAND_MONITORING = Path("/home/facu-edge/Sand Monitoring")
sys.path.insert(0, str(SAND_MONITORING / "analisis"))
sys.path.insert(0, str(SAND_MONITORING / "analisis" / "placa"))

from revisar import _leer_canales_bin  # noqa: E402
from area_kurtosis import _filtrar_pasabanda, FILTRO_BANDA_HZ, FILTRO_ORDEN  # noqa: E402

FS = 3_906_250.0
VENTANA_MUESTRAS = 195_312  # igual a AREA_WINDOW_SAMPLES default en scope_cfg.sv (50ms)
FA_THRESH = 6  # mismo umbral que revisar.py/area_kurtosis.py

ARCHIVO = SAND_MONITORING / "datos_campo" / "42_1_reposo_20260903_143538_mono_dec32" / "campo_reposo_20260903_143538_0001.bin"

OUT_DIR = Path(__file__).parent


def area_kurtosis_ventana(x):
    """Mismas formulas que area_kurtosis_accum.v (Etapa 5): area =
    sum(|x|)/fs, kurtosis Pearson con aproximacion media=0 (validada en
    la Etapa 5) para comparar contra lo que da el registro de HW, que
    tambien asume media=0."""
    x = x.astype(np.float64)
    n = len(x)
    sum_abs = np.sum(np.abs(x))
    sum_x2 = np.sum(x * x)
    sum_x4 = np.sum(x * x * x * x)
    area = sum_abs / FS
    m2 = sum_x2 / n
    m4 = sum_x4 / n
    kurt = (m4 / (m2 * m2)) if m2 > 0 else 0.0  # Pearson (SIN restar 3) - igual que revisar.py/
    # area_kurtosis.py (scipy_kurtosis(..., fisher=False)), no el default de scipy
    return dict(area=float(area), kurtosis=float(kurt),
                sum_abs=int(round(sum_abs)), sum_x2=int(round(sum_x2)), sum_x4=int(round(sum_x4)))


def escribir_readmemh(muestras_int16, ruta):
    with open(ruta, "w") as f:
        for v in muestras_int16:
            f.write(f"{np.uint16(v):04x}\n")


def main():
    print(f"Leyendo {ARCHIVO.name} ...")
    ch0, ch1, meta = _leer_canales_bin(ARCHIVO)
    print(f"  {len(ch0)} muestras totales ({len(ch0)/FS:.1f}s a fs={FS:.0f}Hz)")

    n_ventanas = len(ch0) // VENTANA_MUESTRAS
    print(f"  {n_ventanas} ventanas de {VENTANA_MUESTRAS} muestras")

    mejor_evento = None  # (kurtosis, indice)
    mejor_reposo = None  # (kurtosis, indice) - la mas chica, para tener contraste claro

    for i in range(n_ventanas):
        seg = ch0[i * VENTANA_MUESTRAS:(i + 1) * VENTANA_MUESTRAS]
        filtrada = _filtrar_pasabanda(seg.astype(np.float32), FS, banda=FILTRO_BANDA_HZ, orden=FILTRO_ORDEN)
        k = scipy_kurtosis(filtrada, fisher=False)  # Pearson, igual que revisar.py/area_kurtosis.py
        if k >= FA_THRESH and (mejor_evento is None or k > mejor_evento[0]):
            mejor_evento = (k, i)
        if mejor_reposo is None or k < mejor_reposo[0]:
            mejor_reposo = (k, i)

    if mejor_evento is None:
        print("ADVERTENCIA: ninguna ventana de este archivo clasifico como evento "
              f"(kurtosis>={FA_THRESH}). Maximo encontrado: revisar otro archivo.")
        sys.exit(1)

    print(f"  Evento elegido: ventana {mejor_evento[1]} (kurtosis software={mejor_evento[0]:.2f})")
    print(f"  Reposo elegido: ventana {mejor_reposo[1]} (kurtosis software={mejor_reposo[0]:.2f})")

    for nombre, (k_soft, idx) in (("evento", mejor_evento), ("reposo", mejor_reposo)):
        cruda = ch0[idx * VENTANA_MUESTRAS:(idx + 1) * VENTANA_MUESTRAS]
        filtrada = _filtrar_pasabanda(cruda.astype(np.float32), FS, banda=FILTRO_BANDA_HZ, orden=FILTRO_ORDEN)
        ref = area_kurtosis_ventana(filtrada)
        ref["kurtosis_scipy_bias_true"] = float(k_soft)
        ref["ventana_indice"] = idx
        ref["clasificacion"] = "evento" if k_soft >= FA_THRESH else "reposo"

        mem_path = OUT_DIR / f"stimulus_{nombre}_simD.mem"
        escribir_readmemh(cruda, mem_path)
        print(f"  {nombre}: {mem_path.name} ({len(cruda)} muestras), "
              f"referencia: area={ref['area']:.2f} kurtosis={ref['kurtosis']:.3f}")

        import json
        with open(OUT_DIR / f"referencia_{nombre}_simD.json", "w") as f:
            json.dump(ref, f, indent=2)


if __name__ == "__main__":
    main()
