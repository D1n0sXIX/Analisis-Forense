# 📓 Diario Forense — Tema 2: Windows I

**Investigador:** Alex  
**Caso:** Análisis de memoria y malware — Windows  
**Directorio de trabajo:** `~/AnalisisForense/Entregas/Tema-2-Windows`  
**Fecha de inicio:** 26/02/2026  
**Estado:** 🔍 Investigación abierta

---

## 🗂️ Artefactos identificados

| Archivo | Tipo | OS | Perfil Volatility | Fecha captura | Estado |
|---|---|---|---|---|---|
| `DarkComet.zip` | Muestra de malware (RAT) | — | — | — | 🔲 Pendiente |
| `r2d2.rar` | Archivo comprimido protegido | — | — | — | ✅ Crackeado (`infected`) |
| `stuxnet.vmem` | Memory dump VMware | WinXP SP3 x86 | `WinXPSP3x86` | 03/06/2011 | 🔍 En progreso |
| `0zapftis.vmem` | Memory dump VMware (R2D2) | WinXP SP2 x86 | `WinXPSP2x86` | 10/10/2011 | 🔍 En progreso |
| `WIN-TTUMF6EI3O3-20140203-123134.raw` | Memory dump raw | Win7 SP1 x86 | `Win7SP1x86` | 03/02/2014 | 🔍 En progreso |

---

## 📅 Entradas del diario

### Entrada #1 — 26/02/2026 · Reconocimiento inicial

Al listar el contenido del directorio encontramos 3 artefactos comprimidos. Tras extraerlos, el inventario real es:

- **`DarkComet.zip`** — Muestra comprimida de DarkComet, un RAT (Remote Access Trojan) muy conocido que permite control remoto total de sistemas comprometidos.
- **`r2d2.rar`** — Protegido con contraseña. Ataque de diccionario con john + rockyou. Contraseña encontrada: **`infected`**. Contenido: `0zapftis.vmem` (nombre técnico del malware R2D2).
- **`stuxnet.vmem.zip`** → extraído como **`stuxnet.vmem`** — Memory dump de VMware de una máquina infectada con Stuxnet.
- **`WIN-TTUMF6EI3O3-20140203-123134.raw`** — Memory dump en formato raw de una máquina Windows. Nombre de host: `WIN-TTUMF6EI3O3`, fecha de captura: **03/02/2014**. Hallazgo inesperado y de alto interés forense.

```bash
# Crackeo de r2d2.rar
rar2john r2d2.rar > hash_r2d2.txt
john hash_r2d2.txt --wordlist=/usr/share/wordlists/rockyou.txt
# Resultado: infected
unrar x r2d2.rar  # extrae 0zapftis.vmem
```

---

### Entrada #2 — 26/02/2026 · Identificación de perfiles (imageinfo)

Volatility 3 no puede procesar los `.vmem` sin su fichero `.vmss`/`.vmsn` acompañante. Se usa **Volatility 2** para todos los dumps.

```bash
vol.py -f stuxnet.vmem imageinfo
vol.py -f 0zapftis.vmem imageinfo
vol.py -f WIN-TTUMF6EI3O3-20140203-123134.raw imageinfo
```

Resultados:

| Dump | OS identificado | Perfil | Service Pack | Fecha captura |
|---|---|---|---|---|
| `stuxnet.vmem` | Windows XP x86 | `WinXPSP3x86` | SP3 | 03/06/2011 04:31 UTC |
| `0zapftis.vmem` | Windows XP x86 | `WinXPSP2x86` | SP2 | 10/10/2011 17:06 UTC |
| `WIN-TTUMF6EI3O3.raw` | Windows 7 x86 | `Win7SP1x86` | SP1 | 03/02/2014 12:31 UTC |

**Siguiente paso:** Extraer procesos, red, comandos y servicios de cada dump.

---

## 🚩 Flags encontrados

| # | Flag | Ubicación | Técnica utilizada |
|---|---|---|---|
| — | — | — | — |

---

## 🧰 Herramientas utilizadas

| Herramienta | Propósito |
|---|---|
| `vol.py` | Análisis de memoria con Volatility 2 |
| `vol` | Análisis de memoria con Volatility 3 (no compatible con .vmem sin .vmss) |
| `rar2john` | Extracción de hash de archivos RAR protegidos |
| `john` | Ataque de diccionario sobre hashes |
| `unrar` | Extracción de archivos RAR |

---

## 🧰 Arsenal completo del reto

| Herramienta | Categoría | Para qué sirve |
|---|---|---|
| `vol` / `vol.py` | Análisis de memoria | Framework forense para análisis de memory dumps (Volatility 3 / 2) |
| `file` | Identificación | Revela el tipo real de un fichero independientemente de su extensión |
| `strings` | Análisis binario | Muestra cadenas de texto legibles dentro de cualquier binario |
| `exiftool` | Metadatos | Extrae metadatos y detecta anomalías |
| `unzip` / `unrar` | Extracción | Descompresión de archivos zip y rar |

---

## 📌 Notas y pendientes

- [x] ~~Descomprimir los tres artefactos~~
- [x] ~~Crackear contraseña de r2d2.rar~~ → `infected`
- [x] ~~Identificar perfiles con imageinfo~~
- [ ] Analizar procesos en ejecución — `pslist`, `pstree` (los 3 dumps)
- [ ] Analizar conexiones de red — `netscan` (los 3 dumps)
- [ ] Analizar comandos ejecutados — `cmdline`, `cmdscan` (los 3 dumps)
- [ ] Analizar servicios — `svcscan` (los 3 dumps)
- [ ] Buscar código inyectado — `malfind` (los 3 dumps)
- [ ] Cruzar hashes con VirusTotal
- [ ] Analizar muestra DarkComet
