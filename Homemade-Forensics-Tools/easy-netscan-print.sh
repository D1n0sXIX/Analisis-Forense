#!/bin/bash
# D1n0 - Alejandro Maman
# easy-netscan-print.sh — Renders Volatility netscan/netstat output with colors
# Usage: bash easy-netscan-print.sh -w <netscan.txt>   (Windows)
#        bash easy-netscan-print.sh -l <netstat.txt>   (Linux)

RED='\033[0;31m'; ORANGE='\033[0;33m'; CYAN='\033[0;36m'
GREEN='\033[0;32m'; GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

MODE=""
FILE=""

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -w) MODE="windows"; shift ;;
        -l) MODE="linux"; shift ;;
        *)  FILE="$1"; shift ;;
    esac
done

if [ -z "$MODE" ] || [ -z "$FILE" ]; then
    echo "Uso: bash easy-netscan-print.sh -w <netscan.txt>  (Windows)"
    echo "     bash easy-netscan-print.sh -l <netstat.txt>  (Linux)"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo -e "${RED}Error: fichero no encontrado '$FILE'${NC}"
    exit 1
fi

echo -e "\n${BOLD}================================================${NC}"
echo -e "${BOLD} easy-netscan-print — Análisis de red ($MODE)${NC}"
echo -e "${BOLD}================================================${NC}"

if [ "$MODE" = "windows" ]; then
    echo -e "${GRAY}Leyenda: ${GREEN}LISTENING${NC}  ${ORANGE}ESTABLISHED${NC}  ${CYAN}UDP${NC}  ${RED}PID -1 (proceso fantasma)${NC}\n"

    while IFS= read -r line; do
        if [[ "$line" =~ ^Offset ]]; then
            echo -e "${BOLD}${line}${NC}"
            continue
        fi
        [[ -z "$line" ]] && continue

        proto=$(echo "$line" | awk '{print $2}')

        if [[ "$proto" == TCPv* ]]; then
            state=$(echo "$line" | awk '{print $5}')
            pid=$(echo "$line"   | awk '{print $6}' | tr -d ' ')
        else
            state="UDP"
            pid=$(echo "$line"   | awk '{print $5}' | tr -d ' ')
        fi

        color="${NC}"; tag=""

        if [[ "$proto" == UDPv* ]]; then
            color="${CYAN}"
        elif [ "$state" = "LISTENING" ]; then
            color="${GREEN}"
        elif [ "$state" = "ESTABLISHED" ]; then
            color="${ORANGE}"
        fi

        if [[ "$pid" == "-1" ]]; then
            color="${RED}${BOLD}"
            tag=" ⚠  PID -1 (proceso fantasma)"
        fi

        echo -e "${color}${line}${NC}${RED}${tag}${NC}"
    done < "$FILE"

elif [ "$MODE" = "linux" ]; then
    echo -e "${GRAY}Leyenda: ${GREEN}LISTEN${NC}  ${ORANGE}ESTABLISHED${NC}  ${CYAN}UDP${NC}  ${RED}conexión sospechosa${NC}\n"
    echo -e "${BOLD}$(printf '%-8s %-18s %-6s %-18s %-6s %-14s %s' 'Proto' 'IP Local' 'Puerto' 'IP Remota' 'Puerto' 'Estado' 'Proceso')${NC}"
    echo -e "${BOLD}$(printf '%-8s %-18s %-6s %-18s %-6s %-14s %s' '-----' '--------' '------' '---------' '------' '------' '-------')${NC}"

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        proto=$(echo "$line" | awk '{print $1}')
        color="${NC}"; tag=""

        if [ "$proto" = "UNIX" ]; then
            # Ignorar UNIX sockets — demasiado ruido
            continue
        elif [ "$proto" = "TCP" ] || [ "$proto" = "UDP" ]; then
            state=$(echo "$line" | grep -oE 'LISTEN|ESTABLISHED|CLOSE_WAIT|TIME_WAIT|SYN_SENT|FIN_WAIT' | head -1)
            process=$(echo "$line" | awk '{print $NF}' | tr -d ' ')

            if [ "$state" = "LISTEN" ]; then
                color="${GREEN}"
            elif [ "$state" = "ESTABLISHED" ]; then
                color="${ORANGE}"
                # Resaltar procesos sospechosos en conexiones establecidas
                if echo "$process" | grep -qiE "python|sh|nc|bash|perl|ruby|wget|curl"; then
                    color="${RED}${BOLD}"
                    tag=" ⚠  PROCESO SOSPECHOSO CON CONEXIÓN ACTIVA"
                fi
            fi

            echo -e "${color}${line}${NC}${RED}${tag}${NC}"
        fi
    done < "$FILE"
fi

echo -e "\n${BOLD}================================================${NC}\n"
