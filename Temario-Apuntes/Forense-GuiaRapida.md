# Guía Rápida — Forense Completo (T1 + T2 + T3)
## D1n0 - Alejandro Mamán

---
Identificar el Escenario — Árbol de Decisión

```
¿Qué te dan?
│
├── Imagen / PDF / DOCX / fichero con extensión rara
│   └── → ESCENARIO 1: Metadatos + Esteganografía
│
├── ZIP o RAR cifrado  (+/- imagen de disco .dd/.img)
│   └── → ESCENARIO 2: Cracking + Análisis de Disco
│
├── Ficheros de texto con salida de ps, top, /proc
│   └── → ESCENARIO 3: Rootkit Linux (proceso oculto)
│
├── Binario .exe que ejecutar en Windows + Sysinternals/Nirsoft
│   └── → ESCENARIO 4: Análisis Volátil Windows en Vivo
│
├── Fichero .raw / .mem / .vmem (volcado de memoria)
│   └── → ESCENARIO 5: Análisis de Memoria con Volatility
│
└── Imagen de disco Windows o acceso a sistema apagado
    └── → ESCENARIO 6: Artefactos No Volátiles (Registro + Eventos)
```

---

## ESCENARIO 1 — Metadatos + Esteganografía

**Te dan:** imagen JPG/PNG, PDF, DOCX, o varios ficheros con posibles extensiones falsas.
**Objetivo:** encontrar flags en metadatos, en datos ocultos, o en ficheros embebidos.
**Referencia completa:** `Tema1-cheatsheet.md` → secciones Metadatos y Esteganografía

### Procedimiento paso a paso

```bash
# 1: ¿Es lo que parece? ──────────────────────────────────────────
file sospechoso.xxx
exiftool -FileType -MIMEType sospechoso.xxx
# Si la extensión no coincide con FileType → renombrar y continuar

# 2: Metadatos completos ─────────────────────────────────────────
exiftool -a -u sospechoso.xxx
# Campos críticos a revisar:
#   Author, Creator, Comment, Description, Software
#   GPSLatitude, GPSLongitude  → geolocalización
#   CreateDate, ModifyDate     → timeline
#   Todos los campos Custom/Unknown

# 3: Strings (datos en texto plano) ──────────────────────────────
strings sospechoso.xxx | grep -i "flag\|pass\|secret\|hidden\|key"

# 4: ¿Hay ficheros embebidos? (binwalk) ──────────────────────────
binwalk sospechoso.xxx               # detectar
binwalk -e sospechoso.xxx            # extraer automáticamente
# Mirar la carpeta _sospechoso.xxx.extracted/

# 5: Esteganografía (steghide) ───────────────────────────────────
steghide info sospechoso.jpg         # ¿tiene payload?
steghide extract -sf sospechoso.jpg -p ""               # sin contraseña
steghide extract -sf sospechoso.jpg -p "valorDeMetadatos"  # con la pass encontrada

# 6: Esteganografía visual (GIMP) ────────────────────────────────
# Abrir en GIMP:
# 1. Colores → Curvas → mover cada canal R, G, B por separado
# 2. Colores → Componentes → Descomponer → ver canal Alpha
# 3. Colores → Niveles → ajustar punto negro y blanco

# 7: PNG específico ──────────────────────────────────────────────
zsteg sospechoso.png                 # LSB y otros métodos
```

### Checklist de este escenario

- [ ] `file` confirma el tipo real del fichero
- [ ] `exiftool -a -u` revisado campo a campo
- [ ] GPS extraído y geolocalizado (Google Maps con coordenadas decimales)
- [ ] `binwalk -e` ejecutado y carpeta de extracción revisada
- [ ] `steghide extract` probado sin pass y con cada candidata encontrada
- [ ] GIMP: canales R, G, B revisados por separado
- [ ] `strings` filtrado por palabras clave

---

## ESCENARIO 2 — Cracking + Análisis de Disco

**Te dan:** ZIP o RAR cifrado. A veces dentro hay una imagen de SO (`.dd`, `.img`, `.E01`).
**Objetivo:** obtener la contraseña, descomprimir, y analizar el contenido (usuarios, contraseñas, ficheros).
**Referencia completa:** `Tema1-cheatsheet.md` → sección Password Cracking

### Procedimiento paso a paso

```bash
# ── PARTE A: CRACKEAR EL ZIP/RAR ────────────────────────────────────────

# Extraer el hash
zip2john fichero.zip > hash.txt
rar2john fichero.rar > hash.txt
cat hash.txt    # confirmar formato antes de crackear

# Elegir estrategia según pistas del enunciado:

# Opción A — Sin pistas → rockyou directamente
john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
john --wordlist=/usr/share/wordlists/rockyou.txt --rules hash.txt  # si falla

# Opción B — Hay URL o contexto → CeWL
cewl -d 2 -m 5 http://url-del-caso.com -w wordlist.txt
john --wordlist=wordlist.txt hash.txt

# Opción C — Sabes el patrón (ej: "4 letras + 2 dígitos")
crunch 6 6 -t ????%% -o wordlist.txt
john --wordlist=wordlist.txt hash.txt

# Ver resultado
john --show hash.txt

# Descomprimir
unzip -P "contraseña" fichero.zip
unrar x -p"contraseña" fichero.rar

# ── PARTE B: ANALIZAR IMAGEN DE DISCO ───────────────────────────────────

# Montar la imagen (solo lectura)
sudo mount -o loop,ro imagen.dd /mnt/evidencia
ls /mnt/evidencia/

# Si es Windows → extraer hashes de usuarios
find /mnt/evidencia -name "SAM"    2>/dev/null
find /mnt/evidencia -name "SYSTEM" 2>/dev/null
# Normalmente en: /mnt/evidencia/Windows/System32/config/

samdump2 /mnt/evidencia/Windows/System32/config/SYSTEM \
         /mnt/evidencia/Windows/System32/config/SAM

# Crackear hashes NTLM resultantes
hashcat -a 0 -m 1000 ntlm_hashes.txt /usr/share/wordlists/rockyou.txt
john --format=nt --wordlist=/usr/share/wordlists/rockyou.txt ntlm_hashes.txt

# Exploración general
find /mnt/evidencia -name "*.txt" -o -name "*.log" 2>/dev/null
strings imagen.dd | grep -i "flag\|pass\|secret"

# Si es Linux → /etc/passwd + /etc/shadow
cat /mnt/evidencia/etc/passwd
cat /mnt/evidencia/etc/shadow
unshadow passwd shadow > combined.txt
john --wordlist=rockyou.txt combined.txt
```

### Checklist de este escenario

- [ ] Hash extraído con zip2john/rar2john y formato confirmado
- [ ] Cracking lanzado en background ANTES de continuar con otra cosa
- [ ] Contraseña encontrada con `john --show`
- [ ] ZIP/RAR descomprimido correctamente
- [ ] Imagen de disco montada en modo solo lectura
- [ ] SAM + SYSTEM localizados y hashes extraídos
- [ ] Hashes NTLM crackeados con hashcat/john
- [ ] Contraseñas en claro documentadas con su usuario

---

## ESCENARIO 3 — Rootkit Linux (Proceso Oculto)

**Te dan:** 3 ficheros de texto con salida de `ps aux`, `top` y un escáner de `/proc` (o similar).
**Objetivo:** identificar el proceso que el rootkit oculta comparando las tres fuentes.
**Referencia completa:** `Tema2-cheatsheet.md` → sección de procesos

### Procedimiento paso a paso (análisis manual, sin comandos)

```
PASO 1 — Extraer todos los PIDs de cada fuente
  → De ps_aux.txt:    columna PID (segunda columna)
  → De top.txt:       columna PID (primera columna)
  → De proc_scan.txt: directorios /proc/XXXX listados

PASO 2 — Comparar las tres listas
  Hacer una tabla:   PID | En ps | En top | En /proc
  Buscar PIDs que aparezcan en /proc pero NO en ps y/o top
  → Eso es el proceso oculto: el rootkit hookea ps y top pero no puede
    borrar el directorio /proc/PID fácilmente

PASO 3 — Documentar el proceso encontrado
  → PID exacto
  → Nombre del proceso (cmdline en /proc/PID/cmdline)
  → Usuario bajo el que corre (status en /proc/PID/status → Uid:)
  → CPU y memoria consumida (si aparece en alguna fuente)
  → Conexiones de red asociadas (si hay fichero de netstat)

PASO 4 — Explicar por qué es un rootkit
  → "El proceso PID XXXX aparece en /proc pero no en ps aux ni en top,
     lo que indica que el rootkit está hookeando las syscalls que
     utilizan estas herramientas para ocultar el proceso"
```

### Checklist de este escenario

- [ ] Tabla de PIDs construida comparando las tres fuentes
- [ ] PID(s) ocultos identificados con exactitud
- [ ] Nombre, usuario y recursos del proceso documentados
- [ ] Explicación del mecanismo de ocultación redactada

---

## ESCENARIO 4 — Análisis Volátil Windows en Vivo

**Te dan:** un binario `.exe` que ejecutar en Windows + acceso a Sysinternals y Nirsoft.
**Objetivo:** encontrar flags observando qué hace el binario en el sistema.
**Referencia completa:** `Tema2-cheatsheet.md` → secciones Info Volátil y Checklist proceso malicioso

### Pre-ejecución (obligatorio)

```
1. Ejecutar el binario como Administrador
2. Deshabilitar el Firewall de Windows
3. Asegurarse de que la VM tiene acceso a internet
4. Hacer snapshot de la VM ANTES de ejecutar (para poder revertir)
```

### Procedimiento paso a paso — Orden de búsqueda de flags

```
── 1. RED (lo primero, conexiones efímeras) ─────────────────────────────
   TCPView → ¿Conexiones a IPs externas? ¿Puertos no habituales?
   netstat -ano | findstr ESTABLISHED
   → Flag puede estar en: IP destino, puerto, dominio

── 2. PROCESOS ──────────────────────────────────────────────────────────
   Process Explorer / tasklist /v
   → ¿Proceso con nombre raro o path en %TEMP%/%APPDATA%?
   → ¿Proceso hijo de algo que no debería (cmd hijo de word)?
   → Columna "Verified Signer": sin firma = sospechoso
   → Flag puede estar en: nombre, descripción, ruta del ejecutable

── 3. DLLs Y HANDLES ────────────────────────────────────────────────────
   Listdlls.exe -u              → DLLs sin firma del proceso sospechoso
   Handle.exe -p <nombre>       → ficheros y claves de registro abiertos
   → Flag puede estar en: ruta de DLL, fichero abierto, clave de registro

── 4. SERVICIOS ─────────────────────────────────────────────────────────
   sc query type= all | findstr /i "nombre_sospechoso"
   wmic service list brief
   → ¿El binario se instaló como servicio?

── 5. PERSISTENCIA (ARRANQUE) ───────────────────────────────────────────
   AutoRuns → pestaña "Everything" → buscar entradas sin firma o nuevas
   → ¿Añadió claves Run/RunOnce en el registro?
   → Flag puede estar en: nombre de la entrada, comando, ruta

── 6. SESIONES Y USUARIOS ───────────────────────────────────────────────
   LogonSessions.exe -p
   PsLoggedOn.exe
   → ¿Hay sesiones abiertas que no deberían existir?

── 7. PREFETCH Y EJECUCIÓN ──────────────────────────────────────────────
   WinPrefetchView → buscar el nombre del binario
   ExecutedProgramsList
   → ¿Cuántas veces se ejecutó? ¿Cuándo fue la primera vez?

── 8. STRINGS DEL BINARIO (desde Linux) ─────────────────────────────────
   strings binario.exe | grep -i "flag\|http\|pass\|secret\|key"
   strings binario.exe | grep "flag{"
```

### Checklist de este escenario

- [ ] VM con snapshot previo, firewall deshabilitado, run as Administrator
- [ ] TCPView revisado inmediatamente tras ejecutar
- [ ] Process Explorer: árbol de procesos, firmas verificadas
- [ ] Listdlls.exe -u ejecutado sobre el proceso sospechoso
- [ ] Handle.exe ejecutado sobre el proceso sospechoso
- [ ] AutoRuns revisado post-ejecución
- [ ] strings sobre el binario ejecutado
- [ ] Todos los flags documentados con herramienta y método de hallazgo

---

## ESCENARIO 5 — Análisis de Memoria con Volatility

**Te dan:** fichero `.raw`, `.mem`, `.vmem` o `.dmp`.
**Objetivo:** extraer información del sistema en el momento del volcado (procesos, red, credenciales, flags).
**Referencia completa:** `Tema2-cheatsheet.md` → sección Volatility

### Procedimiento paso a paso

```bash
#  1: Perfil (obligatorio primero, todo lo demás depende de esto) ─
volatility -f mem.raw imageinfo
# Copiar el primer perfil sugerido: Win7SP1x64, WinXPSP3x86, etc.
# Guardarlo: export PROFILE="Win7SP1x64"

#  2: Vista rápida de procesos ────────────────────────────────────
volatility -f mem.raw --profile=$PROFILE pstree
# Buscar: procesos con padre incorrecto, nombres raros, rutas en %TEMP%

volatility -f mem.raw --profile=$PROFILE psscan
# Detecta procesos ocultos que pstree/pslist no muestra

#  3: ¿Qué estaban ejecutando? ────────────────────────────────────
volatility -f mem.raw --profile=$PROFILE cmdline
# Argumentos de cada proceso → flags suelen aparecer aquí

volatility -f mem.raw --profile=$PROFILE cmdscan
# Historial de CMD en memoria → comandos ejecutados

volatility -f mem.raw --profile=$PROFILE consoles
# Alternativa a cmdscan, muestra input/output completo de consolas

#  4: Red ─────────────────────────────────────────────────────────
volatility -f mem.raw --profile=$PROFILE netscan
# Conexiones activas y cerradas: IP local, IP remota, puerto, PID, proceso

#  5: Credenciales ────────────────────────────────────────────────
volatility -f mem.raw --profile=$PROFILE hashdump
# Hashes NTLM → crackear con: hashcat -a 0 -m 1000 hashes.txt rockyou.txt

volatility -f mem.raw --profile=$PROFILE lsadump
# LSA secrets: contraseñas de servicios, cuentas de dominio

volatility -f mem.raw --profile=$PROFILE cachedump
# Credenciales cacheadas en registro

#  6: DLLs de proceso sospechoso ──────────────────────────────────
volatility -f mem.raw --profile=$PROFILE dlllist --pid=1234
volatility -f mem.raw --profile=$PROFILE dlldump --pid=1234 -D /tmp/dlls/

#  7: Strings en toda la memoria (net más amplio) ─────────────────
strings mem.raw | grep -i "flag{"
strings mem.raw | grep -i "password\|secret\|hidden\|key"
strings mem.raw | grep "http"    # URLs visitadas o C2

#  8: Volcar proceso sospechoso para análisis ─────────────────────
volatility -f mem.raw --profile=$PROFILE memdump -p 1234 -D /tmp/
strings /tmp/1234.dmp | grep -i "flag\|pass"

volatility -f mem.raw --profile=$PROFILE procdump -p 1234 --dump-dir /tmp/
# Genera ejecutable → analizarlo con strings o VirusTotal

# ── EXTRA: Información del sistema ──────────────────────────────────────
volatility -f mem.raw --profile=$PROFILE shutdowntime   # cuándo se apagó
volatility -f mem.raw --profile=$PROFILE getsids        # SIDs de procesos
volatility -f mem.raw --profile=$PROFILE svcscan        # servicios
```

### Checklist de este escenario

- [ ] `imageinfo` ejecutado y perfil identificado
- [ ] `pstree` revisado: procesos raros, padres incorrectos
- [ ] `psscan` ejecutado: ¿procesos que no aparecen en pstree?
- [ ] `cmdline` revisado campo a campo buscando flags o argumentos raros
- [ ] `cmdscan`/`consoles`: historial de comandos revisado
- [ ] `netscan`: IPs externas y puertos documentados
- [ ] `hashdump`: hashes extraídos y enviados a john/hashcat
- [ ] `strings` sobre el raw completo con grep
- [ ] Proceso sospechoso volcado con `memdump` y analizado con strings

---

## ESCENARIO 6 — Artefactos No Volátiles (Registro + Eventos)

**Te dan:** imagen de disco Windows, acceso a sistema apagado, o los ficheros de registro/eventos directamente.
**Objetivo:** reconstruir actividad del usuario, timeline, conexiones, persistencia.
**Referencia completa:** `Tema3-cheatsheet.md` → todas las secciones

### Preguntas tipo y cómo responderlas

```
¿Cuándo se instaló el SO?
→ HKLM\Software\Microsoft\Windows NT\CurrentVersion  →  valor InstallDate

¿Cuál es la zona horaria? (CRÍTICO para el timeline)
→ HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation

¿Qué usuarios existen en el sistema?
→ HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
→ C:\Users\ (carpetas de perfil)

¿Qué USBs se conectaron y cuándo?
→ HKLM\SYSTEM\CurrentControlSet\Enum\USBSTOR  (qué dispositivos)
→ Eventos 20001 / 20003 / 10000 / 112  (timestamps)

¿A qué redes Wi-Fi se conectó?
→ HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\{GUID}
→ Campo ProfileName = nombre de la red

¿Qué programas se ejecutaron?
→ C:\Windows\Prefetch\*.pf  →  WinPrefetchView (Run Counter + Last Run)
→ ExecutedProgramsList

¿Qué carpetas visitó el usuario?
→ ShellBags  →  ShellBagsView  (path + LastModified)

¿Qué ficheros abrió recientemente?
→ %APPDATA%\Microsoft\Windows\Recent\*.lnk
→ HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs

¿Qué webs visitó?
→ Firefox:  places.sqlite  →  MZHistoryView
→ Chrome:   AppData\Local\Google\Chrome\User Data\Default  →  ChromeHistoryView

¿Hubo fuerza bruta?
→ Eventos Security: muchos 4625 del mismo usuario → seguido de 4624 = éxito

¿Se borraron logs?
→ EventID 1102  (Security log cleared)

¿Se manipuló la hora?
→ EventID 4616

¿Se crearon nuevos usuarios o se elevaron privilegios?
→ EventID 4720 (cuenta creada), 4732 (añadido a grupo), 4672 (admin)

¿Qué hay en el arranque automático?
→ HKLM\...\Run  +  HKCU\...\Run
→ AutoRuns / WhatInStartup

¿Hay miniaturas de imágenes borradas?
→ thumbcache.db  →  Thumbcache Viewer
```

### Procedimiento general con Autopsy

```
1. Nuevo caso → añadir imagen de disco como fuente
2. Activar ingest modules:
   - Recent Activity       → historial navegador, documentos recientes
   - Registry Analysis     → claves de registro
   - Keyword Search        → buscar "flag", "password", etc.
   - File Type Identification
3. Esperar ingest → revisar resultados por categoría
4. Timeline → ordenar eventos por fecha
5. Exportar artefactos relevantes
```

### Checklist de este escenario

- [ ] Zona horaria identificada antes de interpretar cualquier timestamp
- [ ] Usuarios del sistema listados con sus SIDs
- [ ] Claves Run/RunOnce revisadas para persistencia
- [ ] USBs conectados documentados (USBSTOR + eventos)
- [ ] Prefetch analizado: programas ejecutados + frecuencia
- [ ] ShellBags: carpetas visitadas reconstruidas
- [ ] Historial de navegación extraído
- [ ] Eventos filtrados por EventIDs relevantes al caso
- [ ] Timeline construido con los artefactos encontrados

---

## Flujo General de una Investigación Forense

```
ESCENA
  │
  ▼
1. ADQUISICIÓN (sin tocar el original)
   ├── Bloqueo de escritura (write blocker)
   ├── FTK Imager → Export File Hash List  →  hash-original.csv
   ├── FTK Imager → Export File           →  copia a Working/
   ├── FTK Imager → Export File Hash List  →  hash-working.csv
   └── diff hash-original.csv hash-working.csv  →  integridad OK
  │
  ▼
2. INFO VOLÁTIL (sistema encendido → URGENTE, se pierde al apagar)
   ├── Hora              → date /t && time /t
   ├── Usuarios          → LogonSessions.exe -p  /  PsLoggedOn.exe
   ├── Sesiones remotas  → net sessions
   ├── Red               → netstat -ano  /  TCPView
   ├── NetBIOS           → nbtstat -c
   ├── Procesos          → tasklist /v  /  PsList.exe -t
   ├── DLLs/handles      → Listdlls.exe  /  Handle.exe
   ├── Servicios         → sc query type= all
   ├── Historial CMD     → doskey /history
   ├── Historial PS      → type ...ConsoleHost_history.txt
   └── Volcado RAM       → FTK Imager "Capture Memory"
  │
  ▼
3. ANÁLISIS MEMORIA (Volatility 2 en Linux)  →  ESCENARIO 5
  │
  ▼
4. INFO NO VOLÁTIL (disco)  →  ESCENARIO 6
  │
  ▼
5. ARTEFACTOS ESPECÍFICOS
   ├── Metadatos + Stego    →  ESCENARIO 1
   ├── Cracking + Disco     →  ESCENARIO 2
   └── Rootkit Linux        →  ESCENARIO 3
```

---

## Cadena de Custodia

```
CasoXXX/
├── Evidencia-Original/   ← NO tocar jamás
├── Hashes/               ← hash-original.csv + hash-working.csv
├── Working/              ← copia de la evidencia
└── Analisis/             ← trabajar siempre aquí (copia de Working)
```

```bash
diff hash-original.csv hash-working.csv   # sin output = integridad OK
md5sum -c hash-original.txt               # verificar hash contra fichero
```

**→ Más detalle:** `Tema1-cheatsheet.md` → sección Cadena de Custodia

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
