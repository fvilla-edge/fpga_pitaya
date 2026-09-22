#!/bin/bash
# desplegar_bitstream.sh — despliegue seguro de un bitstream custom (.bit.bin,
# ya procesado por bootgen — ver README "Como cargar un bitstream nuevo") a
# una placa Red Pitaya, SIN pisar nunca el default de /opt/redpitaya.
#
# Disenado especificamente para sobrevivir un corte de conexion a mitad de
# transferencia (ej. Starlink, ver reference_placa_banco): el archivo nunca
# se activa directo, primero va a una ruta de staging, se verifica su
# checksum COMPLETO recien llegado (no antes de mandarlo), y solo si
# coincide se activa. Si el corte corta la transferencia a la mitad, el
# checksum no va a coincidir y el script aborta sin tocar nada activo.
#
# Uso:
#   ./desplegar_bitstream.sh <archivo.bit.bin> <IP_placa> [nombre_overlay]
#
# Ejemplo:
#   ./desplegar_bitstream.sh prj/stream_app/out/red_pitaya.bit.bin 192.168.0.135 stream_app
#
# Requiere SSH ya configurado a root@<IP_placa> (clave o password segun la
# placa). Para activar el bitstream ya desplegado hace falta correr aparte
# (a mano, o desde capturar_stream.py si se parcheo campo_common.py):
#   ssh root@<IP_placa> "/opt/redpitaya/sbin/overlay.sh <nombre_overlay> <flag>"
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Uso: $0 <archivo.bit.bin> <IP_placa> [nombre_overlay]" >&2
    exit 1
fi

ARCHIVO="$1"
IP="$2"
NOMBRE="${3:-stream_app}"

if [ ! -f "$ARCHIVO" ]; then
    echo "ERROR: no existe $ARCHIVO" >&2
    exit 1
fi

DESTINO_DIR="/opt/${NOMBRE}"
DESTINO="${DESTINO_DIR}/fpga.bin"
STAGING="/root/staging_${NOMBRE}.bin.partial"
SSH="ssh -o ConnectTimeout=10 root@${IP}"
SCP="scp -o ConnectTimeout=10"

SHA_LOCAL=$(sha256sum "$ARCHIVO" | cut -d' ' -f1)
echo ">>> Checksum local ($ARCHIVO): $SHA_LOCAL"

echo ">>> Transfiriendo a staging (no se activa nada todavia): ${IP}:${STAGING}"
$SSH "mkdir -p ${DESTINO_DIR}"
$SCP "$ARCHIVO" "root@${IP}:${STAGING}"

echo ">>> Verificando checksum COMPLETO ya transferido, antes de activar"
SHA_REMOTO=$($SSH "sha256sum ${STAGING} 2>/dev/null | cut -d' ' -f1" || echo "")

if [ "$SHA_LOCAL" != "$SHA_REMOTO" ]; then
    echo "ERROR: checksum no coincide (local=$SHA_LOCAL remoto=$SHA_REMOTO)." >&2
    echo "Probable corte a mitad de transferencia. Abortando SIN activar nada." >&2
    $SSH "rm -f ${STAGING}" || true
    exit 1
fi
echo ">>> Checksum OK, coincide."

echo ">>> Backup del bitstream custom anterior (si habia uno) antes de reemplazar"
$SSH "
if [ -f ${DESTINO} ]; then
    cp ${DESTINO} ${DESTINO}.bak_\$(date -u +%Y%m%dT%H%M%SZ)
    echo '    backup guardado: ${DESTINO}.bak_'\$(date -u +%Y%m%dT%H%M%SZ)
fi
mv ${STAGING} ${DESTINO}
"

echo ">>> Desplegado y activado en disco: ${DESTINO}"
echo ">>> Para que la FPGA lo cargue de verdad, correr en la placa:"
echo "    /opt/redpitaya/sbin/overlay.sh ${NOMBRE} <cualquier_flag_no_vacio>"
echo ">>> Para revertir al backup anterior: ./revertir_bitstream.sh ${IP} ${NOMBRE}"
