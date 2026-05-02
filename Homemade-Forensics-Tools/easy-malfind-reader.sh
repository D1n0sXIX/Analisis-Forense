#!/bin/bash
# D1n0 - Alejandro Maman
# easy-malfind-reader.sh — Resume el output de malfind de Volatility con colores
# Uso: bash easy-malfind-reader.sh <malfind.txt>

RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
GREEN='\033[0;32m'; GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

if [ "$#" -ne 1 ]; then
    echo "Uso: bash easy-malfind-reader.sh <malfind.txt>"
    exit 1
fi

FICHERO="$1"

if [ ! -f "$FICHERO" ]; then
    echo -e "${RED}Error: no se encuentra '$FICHERO'${NC}"
    exit 1
fi

echo -e "\n${BOLD}================================================${NC}"
echo -e "${BOLD} easy-malfind-reader — Resumen de regiones sospechosas${NC}"
echo -e "${BOLD}================================================${NC}"
echo -e "${GRAY}Leyenda: ${RED}MZ = ejecutable inyectado${NC}  ${YELLOW}PAGE_EXECUTE_READWRITE = sospechoso${NC}\n"

TOTAL=0
TOTAL_MZ=0

proceso=""
pid=""
direccion=""
proteccion=""
flags=""
tiene_mz=0

flush_entrada() {
    [ -z "$proceso" ] && return

    TOTAL=$((TOTAL+1))

    # Color según si tiene MZ o no
    if [ "$tiene_mz" -eq 1 ]; then
        color="${RED}${BOLD}"
        mz_tag=" ⚠  CABECERA MZ DETECTADA (ejecutable inyectado)"
        TOTAL_MZ=$((TOTAL_MZ+1))
    else
        color="${YELLOW}"
        mz_tag=""
    fi

    echo -e "${BOLD}────────────────────────────────────────────────${NC}"
    echo -e "${color}Proceso : $proceso${NC}"
    echo -e "${BOLD}PID     :${NC} $pid"
    echo -e "${BOLD}Address :${NC} $direccion"
    echo -e "${YELLOW}Protección: $proteccion${NC}"
    echo -e "${GRAY}Flags   : $flags${NC}"
    if [ "$tiene_mz" -eq 1 ]; then
        echo -e "${RED}${mz_tag}${NC}"
    fi
    echo ""

    # Reset
    proceso=""
    pid=""
    direccion=""
    proteccion=""
    flags=""
    tiene_mz=0
}

while IFS= read -r linea; do

    # Nueva entrada
    if echo "$linea" | grep -q "^Process:"; then
        flush_entrada
        proceso=$(echo "$linea" | grep -oP "Process: \K[^\s]+")
        pid=$(echo "$linea" | grep -oP "Pid: \K[0-9]+")
        direccion=$(echo "$linea" | grep -oP "Address: \K[^\s]+")
        continue
    fi

    if echo "$linea" | grep -q "^Vad Tag:"; then
        proteccion=$(echo "$linea" | grep -oP "Protection: \K.*")
        continue
    fi

    if echo "$linea" | grep -q "^Flags:"; then
        flags=$(echo "$linea" | sed 's/^Flags: //')
        continue
    fi

    # Detectar cabecera MZ en el hex dump (4d 5a)
    if echo "$linea" | grep -qiE "^\s*0x[0-9a-f]+\s+4d 5a"; then
        tiene_mz=1
    fi

done < "$FICHERO"

# Última entrada
flush_entrada

echo -e "${BOLD}================================================${NC}"
echo -e "Total entradas analizadas : ${BOLD}$TOTAL${NC}"
echo -e "Con cabecera MZ           : ${RED}${BOLD}$TOTAL_MZ${NC}"
echo -e "${BOLD}================================================${NC}\n"
