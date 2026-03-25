#!/bin/bash
# D1n0 - Alejandro Maman

FICHEROS=()
COLUMNAS=()

for arg in "$@"; do
    fichero="${arg%:*}"
    col="${arg##*:}"

    if [ ! -f "$fichero" ]; then
        echo "Error: no se encuentra '$fichero'"
        exit 1
    fi
    if ! [[ "$col" =~ ^[0-9]+$ ]] || [ "$col" -lt 1 ]; then
        echo "Error: columna inválida en '$arg'"
        exit 1
    fi

    FICHEROS+=("$fichero")
    COLUMNAS+=("$col")
done

declare -A PID_CUENTA
declare -A PID_FICHEROS

for i in "${!FICHEROS[@]}"; do
    fichero="${FICHEROS[$i]}"
    col="${COLUMNAS[$i]}"

    while IFS= read -r linea; do
        pid=$(echo "$linea" | awk -v c="$col" '$c ~ /^[0-9]+$/ { print $c }')
        if [ -n "$pid" ]; then
            PID_CUENTA[$pid]=$(( ${PID_CUENTA[$pid]:-0} + 1 ))
            PID_FICHEROS[$pid]+="$fichero "
        fi
    done < "$fichero"
done

TOTAL=${#FICHEROS[@]}
DISCREPANCIAS=0

echo "=============================="
echo " Procesos con discrepancias"
echo "=============================="

for pid in $(echo "${!PID_CUENTA[@]}" | tr ' ' '\n' | sort -n); do
    if [ "${PID_CUENTA[$pid]}" -lt "$TOTAL" ]; then
        DISCREPANCIAS=1
        echo ""
        echo "PID $pid — aparece en ${PID_CUENTA[$pid]} de $TOTAL ficheros"
        echo "Presente en: ${PID_FICHEROS[$pid]}"
        echo "--- Líneas completas ---"
        for i in "${!FICHEROS[@]}"; do
            fichero="${FICHEROS[$i]}"
            col="${COLUMNAS[$i]}"
            linea=$(awk -v c="$col" -v p="$pid" '$c == p' "$fichero")
            if [ -n "$linea" ]; then
                echo "[$fichero] $linea"
            else
                echo "[$fichero] <no encontrado>"
            fi
        done
    fi
done

if [ "$DISCREPANCIAS" -eq 0 ]; then
    echo "No se han encontrado discrepancias entre los ficheros."
fi
