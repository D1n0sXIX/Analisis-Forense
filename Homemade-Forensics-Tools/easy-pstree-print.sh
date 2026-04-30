#!/bin/bash
# D1n0 - Alejandro Maman
# easy-pstree-print.sh — Renders Volatility pstree output with colors and Unicode tree structure
# Usage: bash easy-pstree-print.sh <pstree.txt>

RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
GREEN='\033[0;32m'; GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

# Known malicious / suspicious process names (extend as needed)
SUSPICIOUS="reverse|mimikatz|meterpreter|netcat|nc\.exe|ncat|psexec|rat\.|payload|shell\.exe|inject|malware|exploit"

# Known legitimate system processes
SYSTEM="System|smss\.exe|csrss\.exe|wininit\.exe|winlogon\.exe|services\.exe|lsass\.exe|lsm\.exe|svchost\.exe|explorer\.exe|taskhost\.exe|spoolsv\.exe|dwm\.exe|conhost\.exe"

if [ "$#" -ne 1 ]; then
    echo "Usage: bash easy-pstree-print.sh <pstree.txt>"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo -e "${RED}Error: file not found '$FILE'${NC}"
    exit 1
fi

echo -e "\n${BOLD}================================================${NC}"
echo -e "${BOLD} easy-pstree-print — Process Tree${NC}"
echo -e "${BOLD}================================================${NC}\n"

while IFS= read -r line; do
    # Skip header and blank lines
    [[ "$line" =~ ^Name ]] && continue
    [[ "$line" =~ ^---- ]] && continue
    [[ -z "$line" ]] && continue
    # Skip lines without a process structure
    [[ ! "$line" =~ 0x ]] && continue

    # Extract depth from leading dots
    raw_prefix=$(echo "$line" | grep -oP '^[\. ]*')
    depth=$(echo "$raw_prefix" | tr -cd '.' | wc -c)

    # Extract name, PID, and timestamp
    name=$(echo "$line"  | grep -oP ':\K[^\s]+(?=\s+\d)')
    pid=$(echo "$line"   | grep -oP '(?<=\s)\d{1,6}(?=\s+\d{1,6}\s+\d)' | head -1)
    date=$(echo "$line"  | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}' | head -1)

    [ -z "$name" ] && continue

    # Build indentation
    indent=""
    for ((i=0; i<depth; i++)); do
        if [ $i -lt $((depth-1)) ]; then
            indent="${indent}│   "
        else
            indent="${indent}└── "
        fi
    done

    # Color-code by process type
    if echo "$name" | grep -qiE "$SUSPICIOUS"; then
        color="${RED}${BOLD}"
        tag=" ⚠ SUSPICIOUS"
    elif echo "$name" | grep -qiE "$SYSTEM"; then
        color="${CYAN}"
        tag=""
    else
        color="${YELLOW}"
        tag=""
    fi

    # Format timestamp
    if [ -n "$date" ]; then
        date_str="${GRAY}[${date}]${NC}"
    else
        date_str=""
    fi

    echo -e "${indent}${color}${name}${NC} ${BOLD}(PID: ${pid})${NC} ${date_str}${RED}${tag}${NC}"

done < "$FILE"

echo -e "\n${GRAY}Legend: ${CYAN}blue${NC}=system  ${YELLOW}yellow${NC}=other  ${RED}red=suspicious${NC}\n"
