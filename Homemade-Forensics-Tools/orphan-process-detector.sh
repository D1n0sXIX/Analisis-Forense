#!/bin/bash
# D1n0 - Alejandro Maman
# orphan-detect.sh — Detects processes with orphaned PPIDs in Volatility pslist output
# Usage: bash orphan-detect.sh <pslist.txt>

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; NC='\033[0m'

if [ "$#" -ne 1 ]; then
    echo "Usage: bash orphan-detect.sh <pslist.txt>"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo -e "${RED}Error: file not found '$FILE'${NC}"
    exit 1
fi

# Extract PIDs and PPIDs (skip 2-line header)
mapfile -t PIDS < <(awk 'NR>2 && $3 ~ /^[0-9]+$/ {print $3}' "$FILE")

# Build PID set
declare -A PID_SET
for pid in "${PIDS[@]}"; do
    PID_SET[$pid]=1
done

echo -e "\n${BOLD}==============================${NC}"
echo -e "${BOLD} orphan-detect — Orphaned PPIDs${NC}"
echo -e "${BOLD}==============================${NC}"
echo -e "File: $FILE\n"

FOUND=0
while IFS= read -r line; do
    pid=$(echo "$line"  | awk '{print $3}')
    ppid=$(echo "$line" | awk '{print $4}')
    name=$(echo "$line" | awk '{print $2}')

    if ! [[ "$pid"  =~ ^[0-9]+$ ]] || \
       ! [[ "$ppid" =~ ^[0-9]+$ ]]; then
        continue
    fi

    # PPID 0 (System) is always valid — skip
    if [ "$ppid" -eq 0 ]; then
        continue
    fi

    if [ -z "${PID_SET[$ppid]}" ]; then
        echo -e "${RED}[!] ORPHANED PPID${NC} — Process: ${BOLD}$name${NC} (PID $pid) → PPID $ppid not found in list"
        FOUND=$((FOUND + 1))
    fi
done < <(awk 'NR>2' "$FILE")

if [ "$FOUND" -eq 0 ]; then
    echo -e "${GREEN}No orphaned PPIDs found.${NC}"
else
    echo -e "\n${YELLOW}Total processes with orphaned PPID: $FOUND${NC}"
fi
