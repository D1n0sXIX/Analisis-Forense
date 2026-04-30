#!/bin/bash
# D1n0 - Alejandro Maman
# hidden-process.sh — Detects hidden processes by cross-referencing pslist vs psscan (Volatility)
# Usage: bash hidden-process.sh pslist.txt:3 psscan.txt:3

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

FILES=()
COLUMNS=()

for arg in "$@"; do
    file="${arg%:*}"
    col="${arg##*:}"
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: file not found '$file'${NC}"
        exit 1
    fi
    if ! [[ "$col" =~ ^[0-9]+$ ]] || [ "$col" -lt 1 ]; then
        echo -e "${RED}Error: invalid column in '$arg'${NC}"
        exit 1
    fi
    FILES+=("$file")
    COLUMNS+=("$col")
done

declare -A PID_COUNT
declare -A PID_FILES

for i in "${!FILES[@]}"; do
    file="${FILES[$i]}"
    col="${COLUMNS[$i]}"
    while IFS= read -r line; do
        pid=$(echo "$line" | awk -v c="$col" '$c ~ /^[0-9]+$/ { print $c }')
        if [ -n "$pid" ]; then
            PID_COUNT[$pid]=$(( ${PID_COUNT[$pid]:-0} + 1 ))
            PID_FILES[$pid]+="$file "
        fi
    done < "$file"
done

TOTAL=${#FILES[@]}
DISCREPANCIES=0

echo -e "\n${BOLD}================================================${NC}"
echo -e "${BOLD} hidden-process — Hidden Process Detection${NC}"
echo -e "${BOLD}================================================${NC}"
echo -e "${GRAY}Files analyzed:${NC}"
for f in "${FILES[@]}"; do
    echo -e "  ${CYAN}→ $f${NC}"
done
echo ""

for pid in $(echo "${!PID_COUNT[@]}" | tr ' ' '\n' | sort -n); do
    if [ "${PID_COUNT[$pid]}" -lt "$TOTAL" ]; then
        DISCREPANCIES=1

        echo -e "${RED}${BOLD}[!] HIDDEN PROCESS DETECTED${NC}"
        echo -e "    ${BOLD}PID $pid${NC} — found in ${YELLOW}${PID_COUNT[$pid]} of $TOTAL${NC} files"
        echo -e "    ${GRAY}Present in: ${PID_FILES[$pid]}${NC}"
        echo -e "    ${BOLD}--- Full lines ---${NC}"

        for i in "${!FILES[@]}"; do
            file="${FILES[$i]}"
            col="${COLUMNS[$i]}"
            line=$(awk -v c="$col" -v p="$pid" '$c == p' "$file")
            if [ -n "$line" ]; then
                echo -e "    ${GREEN}[$file]${NC} $line"
            else
                echo -e "    ${RED}[$file] <not found> ← HIDDEN HERE${NC}"
            fi
        done
        echo ""
    fi
done

echo -e "${BOLD}================================================${NC}"
if [ "$DISCREPANCIES" -eq 0 ]; then
    echo -e "${GREEN}No hidden processes found.${NC}"
else
    echo -e "${RED}${BOLD}Hidden processes detected. Review manually.${NC}"
fi
echo -e "${BOLD}================================================${NC}\n"
