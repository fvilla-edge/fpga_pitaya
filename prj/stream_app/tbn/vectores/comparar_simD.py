#!/usr/bin/env python3
"""Simulacion D (RedPitaya-FPGA): reconstruye area/kurtosis a partir de
los registros crudos que volco tb_area_kurtosis_simD.sv (resultado_*.json
en xsim_simD/) y los compara contra la referencia de software
(referencia_*_simD.json, generada por extraer_datos_reales_simD.py) sobre
el MISMO segmento real de datos_campo/.

Mismas formulas que area_kurtosis_accum.v (Etapa 5) y que
extraer_datos_reales_simD.py::area_kurtosis_ventana - no reimplementa
nada distinto, solo junta los dos lados para comparar.
"""
import json
from pathlib import Path

FS = 3_906_250.0
N = 195_312
FA_THRESH = 6

HERE = Path(__file__).parent
XSIM_DIR = HERE / ".." / ".." / "xsim_simD"


def reconstruir(resultado):
    sum_abs = (resultado["sum_abs_hi"] << 32) | resultado["sum_abs_lo"]
    sum_x2  = (resultado["sum_x2_hi"]  << 32) | resultado["sum_x2_lo"]
    sum_x4  = (resultado["sum_x4_hi"]  << 64) | (resultado["sum_x4_mid"] << 32) | resultado["sum_x4_lo"]
    area = sum_abs / FS
    m2 = sum_x2 / N
    m4 = sum_x4 / N
    kurt = (m4 / (m2 * m2)) if m2 > 0 else 0.0
    return dict(area=area, kurtosis=kurt, window_count=resultado["window_count"])


def main():
    for nombre in ("evento", "reposo"):
        with open(XSIM_DIR / f"resultado_{nombre}.json") as f:
            hw = reconstruir(json.load(f))
        with open(HERE / f"referencia_{nombre}_simD.json") as f:
            ref = json.load(f)

        clas_hw = "EVENTO" if hw["kurtosis"] >= FA_THRESH else "reposo"
        clas_ref = ref["clasificacion"].upper() if ref["clasificacion"] == "evento" else "reposo"

        print(f"--- {nombre} (ventana real #{ref['ventana_indice']} de datos_campo/) ---")
        print(f"  HW:  area={hw['area']:.4f}  kurtosis={hw['kurtosis']:.3f}  -> clasifica {clas_hw}")
        print(f"  SW:  area={ref['area']:.4f}  kurtosis={ref['kurtosis']:.3f}  -> clasifica {clas_ref}")
        diff_kurt = abs(hw["kurtosis"] - ref["kurtosis"]) / ref["kurtosis"] * 100
        diff_area = abs(hw["area"] - ref["area"]) / ref["area"] * 100
        print(f"  diferencia: kurtosis {diff_kurt:.1f}%  area {diff_area:.1f}%")
        print(f"  clasificacion: {'COINCIDE' if clas_hw == clas_ref else 'NO COINCIDE'}")
        print()


if __name__ == "__main__":
    main()
