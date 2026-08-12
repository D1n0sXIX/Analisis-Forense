# Referencia Rápida — Forense Completo (T1 + T2 + T3)
## D1n0 - Alejandro Mamán

Tablas y comandos de consulta rápida (sin flujo paso a paso). Para la guía de triaje por escenarios, ver `Forense-GuiaRapida.md`.

---

## Metadatos — Referencia Rápida

```bash
exiftool fichero.jpg                         # todos los metadatos
exiftool -a -u fichero.jpg                   # incluir duplicados y desconocidos
exiftool -r carpeta/                         # recursivo en carpeta
exiftool -csv *.jpg > meta.csv               # exportar a CSV
exiftool -FileType -MIMEType sospechoso.xxx  # tipo real vs extensión
metagoofil -d ejemplo.com -t pdf,doc -o /salida/
```

**→ Más detalle:** `Tema1-cheatsheet.md` → sección Metadatos

---

## Password Cracking — Referencia Rápida

```bash
zip2john fichero.zip > hash.txt  |  rar2john fichero.rar > hash.txt
john --wordlist=rockyou.txt hash.txt
john --wordlist=rockyou.txt --rules hash.txt
john --show hash.txt
hashcat -a 0 -m 13600 hash.txt rockyou.txt   # ZIP
hashcat -a 0 -m 1000  hash.txt rockyou.txt   # NTLM
unzip -P "pass" fichero.zip  |  unrar x -p"pass" fichero.rar
```

| `-m` hashcat | Tipo |
|-------------|------|
| `0` | MD5 |
| `1000` | NTLM |
| `13600` | ZIP |
| `12500` | RAR3 |

**→ Más detalle:** `Tema1-cheatsheet.md` → sección Password Cracking

---

## Esteganografía — Referencia Rápida

```bash
steghide info foto.jpg
steghide extract -sf foto.jpg -p ""
steghide extract -sf foto.jpg -p "contraseña"
binwalk -e foto.jpg
zsteg foto.png
strings foto.jpg | grep -i "flag"
# GIMP: Colores → Curvas / Componentes → Descomponer / Niveles
```

**→ Más detalle:** `Tema1-cheatsheet.md` → sección Esteganografía

---

## Información Volátil Windows — Referencia Rápida

| Qué obtener | Comando |
|-------------|---------|
| Hora | `date /t` · `time /t` |
| Usuarios logueados | `LogonSessions.exe -p` · `PsLoggedOn.exe` |
| Sesiones remotas | `net sessions` |
| Conexiones + PID | `netstat -ano` · `TCPView` |
| Caché NetBIOS | `nbtstat -c` |
| Procesos | `tasklist /v` · `PsList.exe -t` |
| DLLs | `Listdlls.exe -p PID` |
| Handles | `Handle.exe -p PID` |
| Servicios | `sc query type= all` |
| Historial CMD | `doskey /history` |
| Historial PS | `type $env:APPDATA\...\ConsoleHost_history.txt` |

**→ Más detalle:** `Tema2-cheatsheet.md` → sección Info Volátil

---

## Volatility 2 — Referencia Rápida

```bash
volatility -f mem.raw imageinfo
volatility -f mem.raw --profile=P pslist / pstree / psscan
volatility -f mem.raw --profile=P cmdline / cmdscan / consoles
volatility -f mem.raw --profile=P netscan
volatility -f mem.raw --profile=P hashdump / lsadump / cachedump
volatility -f mem.raw --profile=P dlllist --pid=X
volatility -f mem.raw --profile=P memdump -p X -D /tmp/
volatility -f mem.raw --profile=P shutdowntime
strings mem.raw | grep -i "flag{"
```

**→ Más detalle:** `Tema2-cheatsheet.md` → sección Volatility

---

## Registro Windows — Claves Forenses Clave

| Qué buscar | Clave |
|-----------|-------|
| Versión SO | `HKLM\Software\Microsoft\Windows NT\CurrentVersion` |
| Hostname | `HKLM\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName` |
| **Zona horaria** | `HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation` |
| USB conectados | `HKLM\SYSTEM\CurrentControlSet\Enum\USBSTOR` |
| Wi-Fi usadas | `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\{GUID}` |
| Shares | `HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Shares` |
| Inicio (máquina) | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run` |
| Inicio (usuario) | `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` |

**→ Más detalle:** `Tema3-cheatsheet.md` → sección Registro de Windows

---

## Artefactos de Disco — Rutas Clave

| Artefacto | Ruta | Herramienta |
|-----------|------|-------------|
| Hibernate | `C:\hiberfil.sys` | Volatility |
| Paginación | `C:\pagefile.sys` | strings |
| Miniaturas | `C:\Users\<usr>\AppData\Local\Microsoft\Windows\Explorer\thumbcache.db` | Thumbcache Viewer |
| Prefetch | `C:\Windows\Prefetch\*.pf` | WinPrefetchView |
| ShellBags | `NTUSER.DAT\...\Shell\BagMRU` | ShellBagsView |
| Accesos directos | `%APPDATA%\Microsoft\Windows\Recent\*.lnk` | — |
| Eventos | `%SystemRoot%\System32\Winevt\Logs\*.evtx` | Hayabusa |

**→ Más detalle:** `Tema3-cheatsheet.md` → sección Análisis de Ficheros

**Ver también:** `SistemaFicheros.md` para la teoría de NTFS/`$MFT` subyacente a estos artefactos (resident/non-resident, timestamps SI/FN, fixup).

---

## Navegadores — Rutas Clave

| Browser | Artefacto | Ruta |
|---------|-----------|------|
| Firefox | Historial | `AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release\places.sqlite` |
| Firefox | Cookies | `...\cookies.sqlite` |
| Chrome | Todo | `AppData\Local\Google\Chrome\User Data\Default` |
| Edge/IE | Historial | `AppData\Local\Microsoft\Windows\History` |

**→ Más detalle:** `Tema3-cheatsheet.md` → sección Caché, Cookies e Historial

---

## EventIDs — Referencia Rápida

| ID | Evento |
|----|--------|
| `4624` | Login exitoso |
| `4625` | Login fallido |
| `4672` | Login con privilegios admin |
| `4720` | Cuenta creada |
| `4726` | Cuenta eliminada |
| `4732` | Añadido a grupo |
| `4688` | Proceso creado |
| `4698` | Tarea programada creada |
| `4719` | Auditoría cambiada |
| `1102` | Log de seguridad borrado |
| `6005/6006` | Encendido / apagado |

| Ataque | Indicador |
|--------|-----------|
| Fuerza bruta | Muchos `4625` → `4624` |
| Logs borrados | `1102` |
| Hora manipulada | `4616` |
| Auditoría off | `4719` |
| USB | `20001/20003/10000` |

**→ Más detalle:** `Tema3-cheatsheet.md` → sección Eventos de Windows

---

## Checklist — Proceso Malicioso

| Verificar | Señal de alarma |
|-----------|----------------|
| Ruta | `svchost.exe` fuera de `C:\Windows\System32\` |
| Firma digital | Sin firma o firma desconocida |
| Nombre | Typosquatting: `svch0st`, `explorer32` |
| Proceso padre | `lsass.exe` debe ser hijo de `wininit.exe` |
| Procesos hijos | `cmd.exe` hijo de `word.exe` → sospechoso |
| Red | `lsass.exe` con conexión exterior → crítico |

```
System → smss.exe → wininit.exe → lsass.exe
                              → services.exe → svchost.exe
       → winlogon.exe → userinit.exe → explorer.exe
```

**→ Más detalle:** `Tema2-cheatsheet.md` → sección Checklist

---

## Herramientas — Tabla Rápida

| Herramienta | Suite | Escenario |
|-------------|-------|-----------|
| **FTK Imager** | AccessData | Adquisición, hashes, volcado RAM |
| **exiftool** | — | E1: Metadatos |
| **binwalk** | — | E1: Ficheros embebidos |
| **steghide** | — | E1: Esteganografía |
| **GIMP** | — | E1: Esteganografía visual |
| **zsteg** | — | E1: Esteganografía PNG |
| **zip2john / rar2john** | John | E2: Extraer hash |
| **john** | John | E2/E5: Crackear hashes |
| **hashcat** | — | E2/E5: Crackear hashes (GPU) |
| **crunch** | — | E2: Generar wordlists por patrón |
| **CeWL** | — | E2: Generar wordlists desde web |
| **samdump2** | — | E2: Extraer hashes de SAM/SYSTEM |
| **Volatility** | — | E5: Análisis de memoria |
| **TCPView** | Sysinternals | E4: Conexiones en tiempo real |
| **Process Explorer** | Sysinternals | E4: Procesos y firmas |
| **PsList / PsLoggedOn** | Sysinternals | E4: Procesos y usuarios |
| **LogonSessions** | Sysinternals | E4: Sesiones activas |
| **Handle / Listdlls** | Sysinternals | E4: Handles y DLLs |
| **AutoRuns** | Sysinternals | E4/E6: Arranque automático |
| **psloglist** | Sysinternals | E6: Búsqueda en eventos |
| **WhatInStartup** | Nirsoft | E4/E6: Arranque (simple) |
| **WinPrefetchView** | Nirsoft | E4/E6: Prefetch |
| **ExecutedProgramsList** | Nirsoft | E6: Programas ejecutados |
| **ShellBagsView** | Nirsoft | E6: Carpetas visitadas |
| **Thumbcache Viewer** | — | E6: Miniaturas |
| **MZCacheView/CookiesView/HistoryView** | Nirsoft | E6: Firefox |
| **ChromeCacheView/CookiesView/HistoryView** | Nirsoft | E6: Chrome |
| **IECacheView/CookiesView/HistoryView** | Nirsoft | E6: Edge/IE |
| **DB Browser for SQLite** | — | E6: Ficheros .sqlite |
| **Hayabusa** | — | E6: Análisis automático de eventos |
| **bulk_extractor** | — | E6: Recuperar eventos borrados |
| **Autopsy** | — | E6: Framework forense completo |
| **metagoofil** | — | OSINT: metadatos de dominio |

**Herramientas MFT (ver `SistemaFicheros.md`):** MFTECmd/analyzeMFT (parseo), TimeLine Explorer/visidata (análisis del CSV), HxD/ghex/ImHex (hex editor, recuperación de contenido resident).
