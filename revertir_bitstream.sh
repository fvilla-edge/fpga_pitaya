#!/bin/bash
# revertir_bitstream.sh — rollback de un comando: vuelve un bitstream custom
# (desplegado con desplegar_bitstream.sh) al backup mas reciente. NUNCA toca
# el default de /opt/redpitaya (ese no se pisa nunca, ver README).
#
# Uso:
#   ./revertir_bitstream.sh <IP_placa> [nombre_overlay]
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Uso: $0 <IP_placa> [nombre_overlay]" >&2
    exit 1
fi

IP="$1"
NOMBRE="${2:-stream_app}"
DESTINO_DIR="/opt/${NOMBRE}"
SSH="ssh -o ConnectTimeout=10 root@${IP}"

echo ">>> Buscando el backup mas reciente en ${IP}:${DESTINO_DIR}/"
ULTIMO=$($SSH "cd ${DESTINO_DIR} 2>/dev/null && ls -t fpga.bin.bak_* 2>/dev/null | head -1" || echo "")

if [ -z "$ULTIMO" ]; then
    echo "ERROR: no hay ningun backup (fpga.bin.bak_*) en ${DESTINO_DIR} para revertir." >&2
    exit 1
fi

echo ">>> Restaurando: ${ULTIMO}"
$SSH "cp ${DESTINO_DIR}/${ULTIMO} ${DESTINO_DIR}/fpga.bin"

echo ">>> Revertido a ${ULTIMO}."
echo ">>> Para que la FPGA lo recargue de verdad, correr en la placa:"
echo "    /opt/redpitaya/sbin/overlay.sh ${NOMBRE} <cualquier_flag_no_vacio>"
