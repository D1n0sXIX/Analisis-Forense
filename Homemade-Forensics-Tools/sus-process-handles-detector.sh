#!/bin/bash
# D1n0 - Alejandro Maman
# sus-process-handles-detector.sh — Analyzes Volatility handles output for suspicious activity
# Usage: bash sus-process-handles-detector.sh <handles_output.txt>

RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

if [ "$#" -ne 1 ]; then
    echo "Usage: bash sus-process-handles-detector.sh <handles_output.txt>"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo -e "${RED}Error: file not found '$FILE'${NC}"
    exit 1
fi

echo -e "\n${BOLD}================================================${NC}"
echo -e "${BOLD} sus-process-handles-detector — Handle Analysis${NC}"
echo -e "${BOLD}================================================${NC}"
echo -e "File: $FILE\n"

alert() {
    local category="$1"
    local line="$2"
    echo -e "${RED}[!] $category${NC}"
    echo -e "    ${line}\n"
}

TOTAL=0

while IFS= read -r line; do
    [[ "$line" =~ ^Offset ]] && continue
    [[ "$line" =~ ^----- ]] && continue
    [[ -z "$line" ]] && continue

    type=$(echo "$line"   | awk '{print $5}')
    detail=$(echo "$line" | awk '{for(i=6;i<=NF;i++) printf $i" "; print ""}')

    # Network connections
    if [[ "$type" == "File" ]]; then
        if echo "$detail" | grep -qiE '\\Device\\Tcp|\\Device\\Ip|\\Device\\Afd'; then
            alert "NET — Open network connection handle" "$line"
            TOTAL=$((TOTAL+1))
        fi
    fi

    # User data access
    if [[ "$type" == "File" ]]; then
        if echo "$detail" | grep -qiE 'Documents and Settings|\\Users\\'; then
            alert "USER — Access to user directory" "$line"
            TOTAL=$((TOTAL+1))
        fi
    fi

    # Sensitive registry keys
    if [[ "$type" == "Key" ]]; then
        if echo "$detail" | grep -qiE 'SAM|SECURITY|lsass|Secrets|CurrentControlSet\\Control\\Lsa'; then
            alert "CREDENTIALS — Sensitive registry key access" "$line"
            TOTAL=$((TOTAL+1))
        fi
    fi

    # Handle on another process
    if [[ "$type" == "Process" ]]; then
        if echo "$detail" | grep -qivE 'explorer.exe\([0-9]+\)'; then
            alert "PROCESS — Handle on another process (possible injection)" "$line"
            TOTAL=$((TOTAL+1))
        fi
    fi

    # Handle on a thread in another process
    if [[ "$type" == "Thread" ]]; then
        pid_process=$(echo "$line"   | awk '{print $2}')
        tid_detail=$(echo "$detail"  | grep -oP 'PID \K[0-9]+')
        if [ -n "$tid_detail" ] && [ "$tid_detail" != "$pid_process" ]; then
            alert "THREAD — Handle on thread in another process (possible manipulation)" "$line"
            TOTAL=$((TOTAL+1))
        fi
    fi

    # Suspicious paths
    if [[ "$type" == "File" ]]; then
        if echo "$detail" | grep -qiE '\\Temp\\|\\AppData\\|\\tmp\\|\\Users\\Public\\'; then
            alert "SUSPICIOUS PATH — File in unusual location" "$line"
            TOTAL=$((TOTAL+1))
        fi
    fi

done < "$FILE"

echo -e "${BOLD}================================================${NC}"
if [ "$TOTAL" -eq 0 ]; then
    echo -e "${CYAN}No suspicious handles detected.${NC}"
else
    echo -e "${RED}Total alerts: $TOTAL${NC}"
fi
echo -e "${BOLD}================================================${NC}\n"
