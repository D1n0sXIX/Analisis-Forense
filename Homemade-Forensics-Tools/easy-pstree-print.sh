#!/bin/bash
# D1n0 - Alejandro Maman
# easy-pstree-print.sh — Renders Volatility pstree output with colors and Unicode tree structure
# Usage: bash easy-pstree-print.sh -w <pstree.txt>   (Windows)
#        bash easy-pstree-print.sh -l <pstree.txt>   (Linux)

RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
GREEN='\033[0;32m'; GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

SUSPICIOUS="reverse|mimikatz|meterpreter|netcat|nc\.exe|ncat|psexec|rat\.|payload|shell\.exe|inject|malware|exploit|avml|socat"

SYSTEM_WIN="System|smss\.exe|csrss\.exe|wininit\.exe|winlogon\.exe|services\.exe|lsass\.exe|lsm\.exe|svchost\.exe|explorer\.exe|taskhost\.exe|spoolsv\.exe|dwm\.exe|conhost\.exe"
SYSTEM_LIN="systemd|kthreadd|sshd|cron|rsyslogd|NetworkManager|dbus|lightdm|Xorg|init|agetty|login|bash|sh|python|perl"

MODE=""
FILE=""

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -w) MODE="windows"; shift ;;
        -l) MODE="linux"; shift ;;
        *)  FILE="$1"; shift ;;
    esac
done

if [ -z "$MODE" ] || [ -z "$FILE" ]; then
    echo "Uso: bash easy-pstree-print.sh -w <pstree.txt>  (Windows)"
    echo "     bash easy-pstree-print.sh -l <pstree.txt>  (Linux)"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo -e "${RED}Error: fichero no encontrado '$FILE'${NC}"
    exit 1
fi

echo -e "\n${BOLD}================================================${NC}"
echo -e "${BOLD} easy-pstree-print — Árbol de procesos ($MODE)${NC}"
echo -e "${BOLD}================================================${NC}\n"

if [ "$MODE" = "windows" ]; then
    SYSTEM="$SYSTEM_WIN"
    while IFS= read -r line; do
        [[ "$line" =~ ^Name ]] && continue
        [[ "$line" =~ ^---- ]] && continue
        [[ -z "$line" ]] && continue
        [[ ! "$line" =~ 0x ]] && continue

        raw_prefix=$(echo "$line" | grep -oP '^[\. ]*')
        depth=$(echo "$raw_prefix" | tr -cd '.' | wc -c)

        name=$(echo "$line" | grep -oP ':\K[^\s]+(?=\s+\d)')
        pid=$(echo "$line"  | grep -oP '(?<=\s)\d{1,6}(?=\s+\d{1,6}\s+\d)' | head -1)
        date=$(echo "$line" | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}' | head -1)

        [ -z "$name" ] && continue

        indent=""
        for ((i=0; i<depth; i++)); do
            if [ $i -lt $((depth-1)) ]; then
                indent="${indent}│   "
            else
                indent="${indent}└── "
            fi
        done

        if echo "$name" | grep -qiE "$SUSPICIOUS"; then
            color="${RED}${BOLD}"; tag=" ⚠ SOSPECHOSO"
        elif echo "$name" | grep -qiE "$SYSTEM"; then
            color="${CYAN}"; tag=""
        else
            color="${YELLOW}"; tag=""
        fi

        extra="${GRAY}[${date}]${NC}"
        echo -e "${indent}${color}${name}${NC} ${BOLD}(PID: ${pid})${NC} ${extra}${RED}${tag}${NC}"

    done < "$FILE"

elif [ "$MODE" = "linux" ]; then
    SYSTEM="$SYSTEM_LIN"
    while IFS= read -r line; do
        [[ "$line" =~ ^Name ]] && continue
        [[ "$line" =~ ^---- ]] && continue
        [[ -z "$line" ]] && continue

        # Extraer profundidad (número de puntos al inicio)
        raw_prefix=$(echo "$line" | grep -oP '^\.+')
        depth=${#raw_prefix}

        # Extraer nombre, PID y UID
        name=$(echo "$line" | awk '{print $1}' | tr -d '.')
        pid=$(echo "$line"  | awk '{print $2}')
        uid=$(echo "$line"  | awk '{print $3}')

        [ -z "$name" ] && continue
        [[ ! "$pid" =~ ^[0-9]+$ ]] && continue

        indent=""
        for ((i=0; i<depth; i++)); do
            if [ $i -lt $((depth-1)) ]; then
                indent="${indent}│   "
            else
                indent="${indent}└── "
            fi
        done

        if echo "$name" | grep -qiE "$SUSPICIOUS"; then
            color="${RED}${BOLD}"; tag=" ⚠ SOSPECHOSO"
        elif echo "$name" | grep -qiE "$SYSTEM"; then
            color="${CYAN}"; tag=""
        else
            color="${YELLOW}"; tag=""
        fi

        # Mostrar UID si existe
        if [ -n "$uid" ]; then
            extra="${GRAY}[UID: ${uid}]${NC}"
        else
            extra=""
        fi

        echo -e "${indent}${color}${name}${NC} ${BOLD}(PID: ${pid})${NC} ${extra}${RED}${tag}${NC}"

    done < "$FILE"
fi

echo -e "\n${GRAY}Leyenda: ${CYAN}azul${NC}=sistema  ${YELLOW}amarillo${NC}=otro  ${RED}rojo=sospechoso${NC}\n"
