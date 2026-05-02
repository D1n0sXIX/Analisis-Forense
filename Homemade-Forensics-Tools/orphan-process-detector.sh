#!/bin/bash
# D1n0 - Alejandro Maman
# orphan-process-detector.sh — Detects processes with orphaned PPIDs in Volatility pslist output
# Usage: bash orphan-process-detector.sh [-w] <pslist.txt>
#
# NOTE: Windows-only. Linux pslist (linux_pslist) does not expose a PPID column,
# so orphaned-PPID detection is not applicable to Linux memory dumps.
# The -w flag is accepted for explicitness/symmetry with the other tools.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

MODE="windows"
FILE=""

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -w) MODE="windows"; shift ;;
        -l)
            echo -e "${RED}Error: this script is Windows-only.${NC}"
            echo -e "${YELLOW}Linux pslist does not include a PPID column,${NC}"
            echo -e "${YELLOW}so orphaned-PPID detection cannot be performed on Linux dumps.${NC}"
            exit 1
            ;;
        -h|--help)
            echo "Usage: bash orphan-process-detector.sh [-w] <pslist.txt>"
            echo ""
            echo "Detects processes whose PPID does not exist in the pslist."
            echo "Windows-only — relies on the PPID column produced by Volatility's pslist plugin."
            exit 0
            ;;
        *)  FILE="$1"; shift ;;
    esac
done

if [ -z "$FILE" ]; then
    echo "Usage: bash orphan-process-detector.sh [-w] <pslist.txt>"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo -e "${RED}Error: file not found '$FILE'${NC}"
    exit 1
fi

# Extract PIDs (skip 2-line header)
mapfile -t PIDS < <(awk 'NR>2 && $3 ~ /^[0-9]+$/ {print $3}' "$FILE")

# Build PID set
declare -A PID_SET
for pid in "${PIDS[@]}"; do
    PID_SET[$pid]=1
done

echo -e "\n${BOLD}==============================${NC}"
echo -e "${BOLD} orphan-detect — Orphaned PPIDs (Windows)${NC}"
echo -e "${BOLD}==============================${NC}"
echo -e "${CYAN}Note: Windows-only (relies on PPID column from pslist).${NC}"
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
