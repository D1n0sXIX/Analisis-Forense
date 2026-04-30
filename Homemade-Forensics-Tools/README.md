# 🔍 Homemade Forensics Tools

A collection of Bash scripts for **memory forensics and volatile analysis**, designed to work alongside [Volatility 2](https://github.com/volatilityfoundation/volatility) output. Built during hands-on forensic coursework and CTF practice.

> All scripts are read-only analyzers — they process text files and produce no side effects on the system.

---

## 📁 Tools Overview

| Script | Input | Purpose |
|---|---|---|
| `hidden-process.sh` | `pslist.txt`, `psscan.txt` | Detect hidden processes by cross-referencing two Volatility plugins |
| `orphan-detect.sh` | `pslist.txt` | Flag processes whose parent PID no longer exists (PPID spoofing / rootkits) |
| `sus-process-handles-detector.sh` | `handles.txt` | Scan a process's open handles for suspicious activity |
| `easy-pstree-print.sh` | `pstree.txt` | Colorized, indented process tree with known-suspicious name flagging |
| `easy-netscan-print.sh` | `netscan.txt` | Colorized network scan output with state and ghost-PID highlighting |

---

## ⚙️ Prerequisites

- **Bash** 4.0+ (available on any Linux distro / WSL / Kali)
- **Volatility 2** for generating the input files
- Standard Unix tools: `awk`, `grep`, `tr`

---

## 🚀 Usage

### 1. `hidden-process.sh` — Hidden Process Detector

Cross-references PIDs from two Volatility outputs (e.g. `pslist` vs `psscan`). A PID present in `psscan` but absent from `pslist` indicates a process actively hiding from the OS process list — a strong rootkit indicator.

```bash
# Generate inputs
vol.py -f memory.raw --profile=Win7SP1x64 pslist > pslist.txt
vol.py -f memory.raw --profile=Win7SP1x64 psscan > psscan.txt

# Run
bash hidden-process.sh pslist.txt:3 psscan.txt:3
#                                 ^           ^
#                         PID column index in each file
```

The `:N` suffix tells the script which column holds the PID in each file. Adjust if your output format differs.

---

### 2. `orphan-detect.sh` — Orphan PPID Detector

Checks every process's PPID against the known PID list. If a parent PID doesn't exist, the process either started after its parent died (legitimate but rare) or is using PPID spoofing to blend in.

```bash
vol.py -f memory.raw --profile=Win7SP1x64 pslist > pslist.txt
bash orphan-detect.sh pslist.txt
```

> PPID 0 (System) is automatically excluded as it is always valid.

---

### 3. `sus-process-handles-detector.sh` — Suspicious Handle Analyzer

Takes the output of Volatility's `handles` plugin for a specific process and flags:

| Category | What it catches |
|---|---|
| `NET` | Open handles to `\Device\Tcp`, `\Device\Afd` etc. |
| `USER` | Access to `\Users\` or `Documents and Settings` |
| `CREDENTIALS` | Registry keys: `SAM`, `SECURITY`, `Lsa\Secrets` |
| `PROCESS` | Handle on another process (possible injection) |
| `THREAD` | Handle on a thread in a different process |
| `SUSPICIOUS PATH` | Files in `\Temp\`, `\AppData\`, `\Users\Public\` |

```bash
vol.py -f memory.raw --profile=Win7SP1x64 handles -p <PID> > handles.txt
bash sus-process-handles-detector.sh handles.txt
```

---

### 4. `easy-pstree-print.sh` — Colorized Process Tree

Renders Volatility's `pstree` output as a proper Unicode tree with color coding:

- 🔵 **Blue** — Known system processes (`svchost.exe`, `lsass.exe`, `explorer.exe`…)
- 🟡 **Yellow** — Unknown / third-party processes
- 🔴 **Red + ⚠** — Known malicious names (`mimikatz`, `meterpreter`, `netcat`, `psexec`…)

```bash
vol.py -f memory.raw --profile=Win7SP1x64 pstree > pstree.txt
bash easy-pstree-print.sh pstree.txt
```

---

### 5. `easy-netscan-print.sh` — Colorized Network Scan

Renders Volatility's `netscan` output with color-coded connection states:

- 🟢 **Green** — `LISTENING`
- 🟠 **Orange** — `ESTABLISHED`
- 🔵 **Cyan** — UDP sockets
- 🔴 **Red + ⚠** — PID `-1` (ghost process — no owning process found)

```bash
vol.py -f memory.raw --profile=Win7SP1x64 netscan > netscan.txt
bash easy-netscan-print.sh netscan.txt
```

---

## 🧠 Forensic Notes

- **pslist vs psscan discrepancy**: `pslist` walks the active process linked list; `psscan` scans raw memory for `EPROCESS` structures. A process visible only in `psscan` has unlinked itself from the list — a classic DKOM rootkit technique.
- **Orphan PPIDs**: A terminated parent is not always malicious (e.g. a shell that spawned a daemon). Correlate with timestamps from `pstree` before concluding.
- **Handle analysis**: Run `handles` only on processes already flagged as suspicious to keep output manageable.
- **Ghost PIDs in netscan**: PID `-1` in `netscan` means the connection's owning `EPROCESS` was not resolved — often seen with rootkits that hide their process while keeping a socket open.

---

## 📄 License

Personal/educational use. No warranty. Contributions welcome.

*— D1n0 / Alejandro Mamán*
