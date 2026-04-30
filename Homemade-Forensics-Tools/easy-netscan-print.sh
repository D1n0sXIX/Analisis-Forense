#!/bin/bash
# D1n0 - Alejandro Maman
# easy-netscan-print.sh — Renders Volatility netscan output with colors and state highlighting
# Usage: bash easy-netscan-print.sh <netscan.txt>

RED='\033[0;31m'; ORANGE='\033[0;33m'; CYAN='\033[0;36m'
GREEN='\033[0;32m'; GRAY='\033[0;37m'
BOLD='\033[1m'; NC='\033[0m'

if [ "$#" -lt 1 ]; then
    echo "Usage: bash easy-netscan-print.sh <netscan.txt>"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo -e "${RED}Error: file not found '$FILE'${NC}"
    exit 1
fi

echo -e "\n${BOLD}================================================${NC}"
echo -e "${BOLD} easy-netscan-print — Network Analysis${NC}"
echo -e "${BOLD}================================================${NC}"
echo -e "${GRAY}Legend: ${GREEN}LISTENING${NC}  ${ORANGE}ESTABLISHED${NC}  ${CYAN}UDP${NC}  ${RED}PID -1 (ghost process)${NC}\n"

while IFS= read -r line; do
    if [[ "$line" =~ ^Offset ]]; then
        echo -e "${BOLD}${line}${NC}"
        continue
    fi
    [[ -z "$line" ]] && continue

    proto=$(echo "$line" | awk '{print $2}')

    # TCP: $5=state, $6=PID | UDP: no state column
    if [[ "$proto" == TCPv* ]]; then
        state=$(echo "$line" | awk '{print $5}')
        pid=$(echo "$line"   | awk '{print $6}' | tr -d ' ')
    else
        state="UDP"
        pid=$(echo "$line"   | awk '{print $5}' | tr -d ' ')
    fi

    color="${NC}"
    tag=""

    if [[ "$proto" == UDPv* ]]; then
        color="${CYAN}"
    elif [ "$state" = "LISTENING" ]; then
        color="${GREEN}"
    elif [ "$state" = "ESTABLISHED" ]; then
        color="${ORANGE}"
    fi

    if [[ "$pid" == "-1" ]]; then
        color="${RED}${BOLD}"
        tag=" ⚠  PID -1 (ghost process)"
    fi

    echo -e "${color}${line}${NC}${RED}${tag}${NC}"

done < "$FILE"

echo -e "\n${BOLD}================================================${NC}\n"
