# 🔍 Homemade Forensics Tools

A collection of Bash scripts for **memory forensics and volatile analysis**, designed to work alongside [Volatility 2](https://github.com/volatilityfoundation/volatility) output. Built during hands-on forensic coursework and CTF practice.

> All scripts are read-only analyzers — they process text files and produce no side effects on the system.

---

## 📁 Tools Overview

| Script | Input | Platform | Purpose |
|---|---|---|---|
| `hidden-process.sh` | `pslist.txt`, `psscan.txt` | Win + Linux | Detect hidden processes by cross-referencing two Volatility plugins |
| `orphan-process-detector.sh` | `pslist.txt` | Windows only | Flag processes whose parent PID no longer exists (PPID spoofing / rootkits) |
| `sus-process-handles-detector.sh` | `handles.txt` | Windows only | Scan a process's open handles for suspicious activity |
| `easy-pstree-print.sh` | `pstree.txt` | Win + Linux (`-w` / `-l`) | Colorized, indented process tree with known-suspicious name flagging |
| `easy-netscan-print.sh` | `netscan.txt` / `netstat.txt` | Win + Linux (`-w` / `-l`) | Colorized network output with state and ghost-PID highlighting |
| `easy-malfind-reader.sh` | `malfind.txt` | Win + Linux | Summary of `malfind` / `linux_malfind` output with MZ-header detection |

---

## ⚙️ Prerequisites

- **Bash** 4.0+ (available on any Linux distro / WSL / Kali)
- **Volatility 2** for generating the input files
- Standard Unix tools: `awk`, `grep`, `tr`

---

## 🚀 Usage

### 1. `hidden-process.sh` — Hidden Process Detector

Cross-references PIDs from two Volatility outputs (e.g. `pslist` vs `psscan`, or `linux_pslist` vs `linux_psscan`). A PID present in `psscan` but absent from `pslist` indicates a process actively hiding from the OS process list — a strong rootkit indicator.

```bash
# Windows
vol2 -f memory.raw --profile=Win7SP1x64 pslist > pslist.txt
vol2 -f memory.raw --profile=Win7SP1x64 psscan > psscan.txt
bash hidden-process.sh pslist.txt:3 psscan.txt:3

# Linux
vol2 -f memory.raw --profile=LinuxUbuntu1604x64 linux_pslist > pslistLinux.txt
vol2 -f memory.raw --profile=LinuxUbuntu1604x64 linux_psscan > psscanLinux.txt
bash hidden-process.sh pslistLinux.txt:3 psscanLinux.txt:3
#                                    ^                 ^
#                            PID column index in each file
```

The `:N` suffix tells the script which column holds the PID in each file. Adjust if your output format differs.

---

### 2. `orphan-process-detector.sh` — Orphan PPID Detector  *(Windows only)*

Checks every process's PPID against the known PID list. If a parent PID doesn't exist, the process either started after its parent died (legitimate but rare) or is using PPID spoofing to blend in.

```bash
vol2 -f memory.raw --profile=Win7SP1x64 pslist > pslist.txt
bash orphan-process-detector.sh pslist.txt
# or, equivalently:
bash orphan-process-detector.sh -w pslist.txt
```

> ⚠️ **Windows-only** — `linux_pslist` does not expose a PPID column, so orphan-PPID detection is not applicable to Linux memory dumps. Passing `-l` will exit with an explanatory error.
>
> PPID 0 (System) is automatically excluded as it is always valid.

---

### 3. `sus-process-handles-detector.sh` — Suspicious Handle Analyzer  *(Windows only)*

Takes the output of Volatility's `handles` plugin for a specific process and flags:

| Category | What it catches |
|---|---|
| `NET` | Open handles to `\Device\Tcp`, `\Device\Afd`, etc. |
| `USER` | Access to `\Users\` or `Documents and Settings` |
| `CREDENTIALS` | Registry keys: `SAM`, `SECURITY`, `Lsa\Secrets` |
| `PROCESS` | Handle on another process (possible injection) |
| `THREAD` | Handle on a thread in a different process |
| `SUSPICIOUS PATH` | Files in `\Temp\`, `\AppData\`, `\Users\Public\` |

```bash
vol2 -f memory.raw --profile=Win7SP1x64 handles -p <PID> > handles.txt
bash sus-process-handles-detector.sh handles.txt
```

> ⚠️ **Windows-only** — Volatility's `handles` plugin has no direct equivalent on Linux. For Linux file descriptors use `linux_lsof` and inspect manually (e.g. multiple FDs pointing to the same socket → reverse shell indicator).

---

### 4. `easy-pstree-print.sh` — Colorized Process Tree

Renders Volatility's `pstree` / `linux_pstree` output as a Unicode tree with color coding.

- 🔵 **Blue** — Known system processes (`svchost.exe`, `lsass.exe`, `explorer.exe`, `systemd`, `sshd`, …)
- 🟡 **Yellow** — Unknown / third-party processes
- 🔴 **Red + ⚠** — Known malicious names (`mimikatz`, `meterpreter`, `netcat`, `psexec`, `avml`, `reverse`, …)

```bash
# Windows
vol2 -f memory.raw --profile=Win7SP1x64 pstree > pstree.txt
bash easy-pstree-print.sh -w pstree.txt

# Linux
vol2 -f memory.raw --profile=LinuxUbuntu1604x64 linux_pstree > pstree.txt
bash easy-pstree-print.sh -l pstree.txt
```

---

### 5. `easy-netscan-print.sh` — Colorized Network Output

Renders Volatility's `netscan` (Windows) or `linux_netstat` (Linux) output with color-coded connection states.

**Windows mode (`-w`)**:
- 🟢 **Green** — `LISTENING`
- 🟠 **Orange** — `ESTABLISHED`
- 🔵 **Cyan** — UDP sockets
- 🔴 **Red + ⚠** — PID `-1` (ghost process — no owning process found)

**Linux mode (`-l`)**:
- 🟢 **Green** — `LISTEN`
- 🟠 **Orange** — `ESTABLISHED`
- 🔴 **Red + ⚠** — Suspicious processes (`python`, `sh`, `nc`, `bash`, `perl`, `wget`, `curl`) holding active connections

```bash
# Windows
vol2 -f memory.raw --profile=Win7SP1x64 netscan > netscan.txt
bash easy-netscan-print.sh -w netscan.txt

# Linux
vol2 -f memory.raw --profile=LinuxUbuntu1604x64 linux_netstat > netstat.txt
bash easy-netscan-print.sh -l netstat.txt
```

---

### 6. `easy-malfind-reader.sh` — Malfind Output Summary

Parses Volatility's `malfind` / `linux_malfind` output and produces a clean per-region summary, highlighting regions with an injected MZ header (PE executable signature) on `PAGE_EXECUTE_READWRITE` pages — the textbook injection IoC.

- 🟡 **Yellow** — RWX region (suspicious but no MZ header)
- 🔴 **Red + ⚠** — RWX region **with MZ header** (injected executable)

```bash
# Same usage on Windows and Linux — output format is identical
vol2 -f memory.raw --profile=Win7SP1x64 malfind > malfind.txt
bash easy-malfind-reader.sh malfind.txt
```

The summary tail shows total entries analyzed and how many of them carried an MZ header.

---

## 🧠 Forensic Notes

- **pslist vs psscan discrepancy**: `pslist` walks the active process linked list; `psscan` scans raw memory for `EPROCESS` (Windows) or `task_struct` (Linux) structures. A process visible only in `psscan` has unlinked itself from the list — a classic DKOM rootkit technique.
- **Orphan PPIDs (Windows)**: A terminated parent is not always malicious (e.g. a shell that spawned a daemon and exited). Correlate with timestamps from `pstree` before concluding.
- **Handle analysis (Windows)**: Run `handles` only on processes already flagged as suspicious to keep output manageable.
- **Ghost PIDs in netscan (Windows)**: PID `-1` in `netscan` means the connection's owning `EPROCESS` was not resolved — often seen with rootkits that hide their process while keeping a socket open.
- **Reverse shells on Linux**: `linux_lsof` typically reveals reverse shells as a process with FDs `0`, `1`, `2` and `3` all pointing to the **same socket** — stdin/stdout/stderr have been redirected to a network connection.
- **Malfind hits**: Any RWX region with an MZ header in its first bytes is an injected PE — extract with `procdump -p <PID>` and triage the binary (hash, strings, AV).

---

## 📄 License

Personal/educational use. No warranty. Contributions welcome.

*— D1n0 / Alejandro Mamán*
