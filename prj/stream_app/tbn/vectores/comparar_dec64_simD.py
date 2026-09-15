#!/usr/bin/env python3
"""Compara los resultados de tb_area_kurtosis_dec64_simD.sv (resultado_N.json
en xsim_dec64_simD/) contra la referencia de software (dec64_simD/referencia_N.json)."""
import json
from pathlib import Path

FS = 1_953_125.0
N = 97_656
FA_THRESH = 6

HERE = Path(__file__).parent
XSIM_DIR = HERE / ".." / ".." / "xsim_dec64_simD"
LOTE_DIR = HERE / "dec64_simD"


def reconstruir(r):
    sum_abs = (r["sum_abs_hi"] << 32) | r["sum_abs_lo"]
    sum_x2  = (r["sum_x2_hi"]  << 32) | r["sum_x2_lo"]
    sum_x4  = (r["sum_x4_hi"]  << 64) | (r["sum_x4_mid"] << 32) | r["sum_x4_lo"]
    m2 = sum_x2 / N
    m4 = sum_x4 / N
    kurt = (m4 / (m2 * m2)) if m2 > 0 else 0.0
    return dict(area=sum_abs / FS, kurtosis=kurt)


def main():
    with open(LOTE_DIR / "manifest.json") as f:
        manifest = json.load(f)

    coincidencias = 0
    for entry in manifest:
        idx = entry["idx"]
        with open(XSIM_DIR / f"resultado_{idx}.json") as f:
            hw = reconstruir(json.load(f))
        with open(LOTE_DIR / f"referencia_{idx}.json") as f:
            ref = json.load(f)

        clas_hw = "evento" if hw["kurtosis"] >= FA_THRESH else "reposo"
        ok = clas_hw == ref["clasificacion"]
        coincidencias += ok
        diff_k = abs(hw["kurtosis"] - ref["kurtosis"]) / max(ref["kurtosis"], 0.01) * 100
        print(f"[{idx}] {entry['etiqueta']:20s} ({entry['archivo']}): "
              f"HW kurtosis={hw['kurtosis']:7.2f}  SW kurtosis={ref['kurtosis']:7.2f}  "
              f"diff={diff_k:5.1f}%  clasif_hw={clas_hw:7s} clasif_sw={ref['clasificacion']:7s}  "
              f"{'OK' if ok else 'NO COINCIDE'}")

    print(f"\n{coincidencias}/{len(manifest)} clasificaciones coinciden")


if __name__ == "__main__":
    main()
