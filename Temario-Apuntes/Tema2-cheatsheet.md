# Cheatsheet Tema 2 — Windows I
## D1n0 - Alejandro Mamán

---

## Teoría Importante

### LSA — lsass.exe
- Proceso crítico de Windows que gestiona credenciales de usuario.
- Un atacante puede volcar su contenido en memoria y extraer hashes de contraseñas.
- Ruta legítima: `C:\Windows\System32\lsass.exe` → si aparece en otra ruta, sospechoso.

### SID — Security Identifier
Identificador único para usuarios y grupos. Controla el acceso a recursos.

```
Ejemplo: S-1-5-21-3623811015-3361044348-30300820-1013
         │ │ │  └─────────────────────────────┘  └──┘
         │ │ │         Subautoridad (dominio=21)   RID
         │ │ └── Autoridad (5 = NT)
         │ └──── Versión (siempre 1)
         └────── Marca SID
```

| RID (último número) | Significado |
|---------------------|-------------|
| `500` | Administrador built-in |
| `501` | Guest |
| `1000+` | Usuarios normales |

### Niveles de Integridad
| Nivel | Quién lo tiene | Acceso |
|-------|---------------|--------|
| **Bajo** | Sandbox (ej: Word descargado de internet) | Muy limitado |
| **Medio** | Usuario normal | Mayoría de recursos |
| **Alto** | Administrador | Casi todo |
| **Sistema** | AUTHORITY\SYSTEM | Todo |

### SMB
- Protocolo para compartir recursos en red (ficheros, impresoras).
- Carpetas administrativas: `admin$`, `c$` → requieren privilegios de admin local.
- `IPC$` → carpeta virtual para comunicación entre procesos.
- Históricamente muy vulnerable → prestarle especial atención.

### NetBIOS
- Protocolo Windows habilitado por defecto para resolución de nombres.
- Envía paquetes a **broadcast** preguntando quién tiene ese nombre.
- **Vulnerable a Spoofing** (envenenamiento de tabla caché).
- Obsoleto pero aún activo en muchos entornos.

### RDP
- Administración remota con **interfaz gráfica** (puerto 3389).
- Simula login local → se detecta como autenticación local, NO remota.
- Un atacante puede usar RDP sin GUI simulando la comunicación por terminal.
- Alternativa: **WinRM** (administración remota por línea de comandos).

### NTLM — Autenticación Challenge/Response
```
1. Cliente envía username al servidor
2. Servidor responde con un número aleatorio (challenge)
3. Cliente cifra el challenge con su hash NTLM → envía la respuesta
4. Servidor verifica → acceso concedido o denegado
```
> El hash NTLM tiene 32 caracteres hex. Se puede crackear con john/hashcat (`-m 1000`).

---

## Información Volátil Manual — Comandos Windows

> Información volátil = se pierde al apagar el equipo. Recogerla siempre ANTES de apagar.

### Hora del sistema
```cmd
date /t
time /t
net statistics workstation    ← muestra estadísticas desde cuándo está encendido
```

### Usuarios logueados

#### `PsLoggedOn.exe` (Sysinternals)
Muestra usuarios logueados localmente y de forma remota vía SMB.
```cmd
PsLoggedOn.exe                    # usuarios en el equipo local
PsLoggedOn.exe \\EQUIPO-REMOTO    # usuarios en otro equipo de la red
```

#### `net sessions`
Gestiona y lista sesiones remotas abiertas en el equipo (conexiones SMB entrantes).
```cmd
net sessions                      # lista sesiones remotas: equipo, usuario, tiempo inactivo
net sessions \\192.168.1.10       # sesión de una IP concreta
net sessions \\192.168.1.10 /delete  # cerrar sesión remota
```

#### `LogonSessions.exe` (Sysinternals)
Detalle completo de cada sesión: SID, tipo de login, hora, servidor de login.
```cmd
LogonSessions.exe                 # todas las sesiones activas
LogonSessions.exe -p              # + procesos corriendo en cada sesión
```

| Logon type | Significado |
|-----------|-------------|
| `Interactive` | Login local (teclado/pantalla) |
| `Network` | Login remoto vía SMB/RDP sin GUI |
| `Batch` | Tarea programada |
| `Service` | Servicio de Windows |

---

### Ficheros abiertos

#### `net file`
Nativo de Windows. Muestra ficheros de carpetas compartidas abiertos por usuarios remotos.
```cmd
net file                          # ID, ruta, usuario y bloqueos activos
net file 2 /close                 # cerrar fichero por ID
```

#### `PsFile.exe` (Sysinternals)
Igual que `net file` pero con más detalle: permisos de acceso (Read/Write).
```cmd
psfile.exe                        # ficheros abiertos remotamente en el equipo local
psfile.exe \\EQUIPO-REMOTO        # en un equipo remoto
psfile.exe -c 2                   # cerrar fichero por ID
```

#### `openfiles`
Nativo. Muestra ficheros abiertos por usuarios remotos a través de carpetas compartidas.
```cmd
openfiles                         # lista ficheros abiertos remotamente
openfiles /query /fo LIST         # formato lista (más legible)
openfiles /disconnect /id 2       # desconectar fichero por ID
```
> Requiere que esté habilitada la marca global "mantener lista de objetos": `openfiles /local on` (requiere reinicio).

---

### Información de red

#### `nbtstat`
Muestra y gestiona la tabla caché NetBIOS (nombre → IP de equipos contactados).
```cmd
nbtstat -c                        # tabla caché NetBIOS (nombre, tipo, IP, TTL)
nbtstat -n                        # nombres NetBIOS registrados en el equipo local
nbtstat -r                        # estadísticas de resolución de nombres
nbtstat -R                        # purgar y recargar la caché
nbtstat -a NOMBRE-EQUIPO          # tabla NetBIOS de un equipo remoto por nombre
nbtstat -A 192.168.1.10           # tabla NetBIOS de un equipo remoto por IP
```
> La caché puede ser envenenada (NBNS Spoofing) → verificar si hay entradas inesperadas.

#### `netstat`
```cmd
netstat -ano                      # todas las conexiones TCP/UDP con PID (el más útil)
netstat -o                        # conexiones activas con PID
netstat -r                        # tabla de rutas
netstat -e                        # estadísticas de interfaz (bytes enviados/recibidos)
netstat -b                        # ejecutable responsable de cada conexión (requiere admin)
```

| Flag | Significado |
|------|-------------|
| `-a` | Todas las conexiones y puertos en escucha |
| `-n` | Numérico (no resuelve nombres DNS) |
| `-o` | Muestra el PID de cada conexión |
| `-r` | Tabla de rutas |
| `-e` | Estadísticas Ethernet |
| `-b` | Ejecutable de cada conexión (lento, requiere admin) |

#### `ipconfig`
```cmd
ipconfig                          # IPs de todas las interfaces
ipconfig /all                     # IP, MAC, DNS, DHCP, gateway, NetBIOS
ipconfig /displaydns              # caché DNS local (dominios resueltos recientemente)
ipconfig /flushdns                # limpiar caché DNS
```

#### `TCPView` (Sysinternals) — GUI
Versión gráfica de `netstat -ano` con actualización en tiempo real.
- Muestra: proceso, PID, protocolo, dirección local, dirección remota, estado.
- Click derecho → **End Process** / **Close Connection**.
- Útil para ver qué proceso abre una conexión sospechosa al instante.

---

### Procesos

#### `tasklist`
```cmd
tasklist                          # nombre, PID, sesión, memoria
tasklist /v                       # verbose: + usuario, estado, título de ventana
tasklist /svc                     # servicios alojados en cada proceso (útil para svchost)
tasklist /FI "IMAGENAME eq lsass.exe"   # filtrar por nombre de proceso
tasklist /FI "PID eq 1234"        # filtrar por PID
tasklist /FI "USERNAME eq Javier" # procesos de un usuario concreto
tasklist /m kernel32.dll          # procesos que cargan una DLL concreta
```

| Flag | Significado |
|------|-------------|
| `/v` | Verbose (usuario, memoria, título) |
| `/svc` | Servicios dentro de cada proceso |
| `/FI` | Filtro (`"campo eq valor"`) |
| `/m [dll]` | Procesos que usan una DLL específica |
| `/fo` | Formato: `TABLE`, `LIST`, `CSV` |

#### `wmic process`
```cmd
wmic process get ProcessId,Name,ExecutablePath           # ruta completa del ejecutable
wmic process get ProcessId,Name,CommandLine              # comando con argumentos
wmic process where "ProcessId=1234" get CommandLine      # proceso concreto
```

#### `PsList.exe` (Sysinternals)
```cmd
pslist.exe                        # info básica: PID, CPU, threads, handles, memoria
pslist.exe -x                     # + threads y memoria virtual
pslist.exe -t                     # formato árbol (padre-hijo)
pslist.exe lsass                  # buscar proceso por nombre
pslist.exe -d                     # incluir DLLs cargadas
```

---

### DLLs y handles de procesos

#### `Listdlls.exe` (Sysinternals)
Lista las DLLs cargadas por cada proceso con su ruta, tamaño y base de memoria.
```cmd
Listdlls.exe                      # DLLs de todos los procesos
Listdlls.exe lsass.exe            # DLLs de un proceso por nombre
Listdlls.exe -p 1234              # DLLs de un proceso por PID
Listdlls.exe -u                   # solo DLLs sin firma digital (sospechosas)
Listdlls.exe -v                   # verbose: versión y descripción de cada DLL
```

#### `Handle.exe` (Sysinternals)
Muestra todos los handles (ficheros, claves de registro, sockets) abiertos por procesos.
```cmd
handle.exe                        # todos los handles del sistema
handle.exe -p lsass.exe           # handles de un proceso por nombre
handle.exe -p 1234                # handles de un proceso por PID
handle.exe C:\ruta\fichero.txt    # qué proceso tiene abierto ese fichero
handle.exe -t File                # solo handles de tipo fichero
handle.exe -t Key                 # solo claves de registro
handle.exe -c 0x3C -p 1234       # cerrar un handle específico (hex ID)
```

| Flag | Significado |
|------|-------------|
| `-p` | Filtrar por proceso (nombre o PID) |
| `-t` | Tipo de handle: `File`, `Key`, `Section`... |
| `-c` | Cerrar handle (ID en hex) |
| `-u` | Mostrar nombre del usuario propietario |

---

### Servicios
```cmd
wmic service list brief           # nombre, PID, modo inicio, estado
sc query                          # servicios activos
sc query type= all                # todos (activos + detenidos)
sc qc NOMBRE-SERVICIO             # configuración de un servicio concreto
sc query state= all | findstr "SERVICE_NAME\|STATE"   # resumen rápido
```
> El malware frecuentemente se instala como servicio → buscar servicios con nombres raros, rutas en `%TEMP%` o `%APPDATA%`.

---

### Portapapeles
```cmd
# No hay comando nativo útil en CMD/PowerShell para ver el contenido
# InsideClipboard (Nirsoft) → GUI que muestra el contenido completo del portapapeles
```
> Puede contener contraseñas, rutas, datos copiados por el usuario justo antes del incidente.

---

### Historial de comandos

#### CMD
```cmd
doskey /history                   # historial de la sesión CMD actual (se pierde al cerrar)
```

#### PowerShell
```powershell
# Historial permanente (se guarda en disco entre sesiones)
type $env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt

# O desde PowerShell:
Get-History                       # historial de la sesión actual
Get-Content (Get-PSReadLineOption).HistorySavePath   # historial completo guardado
```

---

## Checklist — Identificar proceso malicioso

Al analizar un proceso sospechoso, verificar:

| Pregunta | Por qué importa |
|----------|----------------|
| ¿Ruta esperada? | `svchost.exe` debe estar en `C:\Windows\System32\`, no en `%TEMP%` |
| ¿Firma digital de Microsoft? | Process Explorer → columna "Verified Signer" |
| ¿Nombre bien escrito? | `svch0st.exe`, `explorer32.exe` → typosquatting |
| ¿Proceso padre correcto? | `lsass.exe` hijo de `wininit.exe`; `svchost.exe` hijo de `services.exe` |
| ¿Procesos hijos esperados? | `cmd.exe`, `powershell.exe` como hijo de `word.exe` → sospechoso |
| ¿SID correcto? | Procesos de sistema deben correr bajo `SYSTEM`, no bajo usuario normal |
| ¿Conexiones de red raras? | `lsass.exe` con conexión exterior → muy sospechoso |

### Procesos típicos legítimos de Windows
```
System → smss.exe → csrss.exe
                 → wininit.exe → lsass.exe
                              → lsm.exe
                              → services.exe → svchost.exe (múltiples)
       → winlogon.exe → userinit.exe → explorer.exe → taskhost.exe
```

---

## Volatility — Análisis de volcado de memoria

### Paso 0 — Identificar perfil
```bash
volatility -f memoria.raw imageinfo
# → Suggested Profile(s): Win7SP1x64, Win10x64...
# Usar el perfil sugerido en todos los comandos
```

### Procesos
```bash
volatility -f mem.raw --profile=Win7SP1x64 pslist       # lista plana de procesos
volatility -f mem.raw --profile=Win7SP1x64 pstree       # árbol padre-hijo
volatility -f mem.raw --profile=Win7SP1x64 psscan       # detecta procesos ocultos
volatility -f mem.raw --profile=Win7SP1x64 cmdline      # binario + argumentos de cada proceso
volatility -f mem.raw --profile=Win7SP1x64 cmdscan      # historial de comandos CMD en memoria
volatility -f mem.raw --profile=Win7SP1x64 consoles     # alternativa a cmdscan
```

### Red
```bash
volatility -f mem.raw --profile=Win7SP1x64 netscan      # conexiones activas/cerradas + PID
```

### DLLs y servicios
```bash
volatility -f mem.raw --profile=Win7SP1x64 dlllist --pid=1180     # DLLs de un proceso
volatility -f mem.raw --profile=Win7SP1x64 dlldump --pid=1180 -D /tmp/dll/   # volcar DLLs
volatility -f mem.raw --profile=Win7SP1x64 svcscan      # servicios del sistema
```

### Credenciales
```bash
volatility -f mem.raw --profile=Win7SP1x64 hashdump     # hashes NTLM (SAM + SYSTEM)
volatility -f mem.raw --profile=Win7SP1x64 cachedump    # credenciales cacheadas en registro
volatility -f mem.raw --profile=Win7SP1x64 lsadump      # LSA secrets
volatility -f mem.raw --profile=Win7SP1x64 getsids      # SIDs de los procesos
```

### Volcado de procesos
```bash
# Volcar memoria completa de un proceso (ejecutable + memoria)
volatility -f mem.raw --profile=Win7SP1x64 memdump -p 524 -D /tmp/

# Volcar solo el ejecutable del proceso (para análisis posterior)
volatility -f mem.raw --profile=Win7SP1x64 procdump -p 1180 --dump-dir /tmp/
```

### Información del sistema
```bash
volatility -f mem.raw --profile=Win7SP1x64 shutdowntime    # último apagado del sistema
```

### Búsqueda de strings en memoria
```bash
strings memoria.raw | grep -i "password"
strings memoria.raw | grep -i "flag{"
```

---

## Orden de análisis forense Windows — Resumen

```
SISTEMA ENCENDIDO (información volátil):
1.  date /t && time /t              → hora del sistema
2.  LogonSessions.exe -p            → usuarios + procesos por sesión
3.  net sessions                    → sesiones remotas abiertas
4.  netstat -ano                    → conexiones de red con PIDs
5.  nbtstat -c                      → caché NetBIOS
6.  tasklist /v                     → procesos corriendo
7.  Listdlls.exe / handle.exe       → DLLs y ficheros por proceso
8.  net file / psfile.exe           → ficheros compartidos abiertos
9.  doskey /history                 → historial CMD
10. type ...ConsoleHost_history.txt → historial PowerShell
11. FTK Imager → Capture Memory     → volcado de RAM

ANÁLISIS MEMORIA (Volatility):
1. imageinfo      → identificar perfil
2. pslist/pstree  → procesos y relaciones padre-hijo
3. psscan         → detectar procesos ocultos
4. cmdline        → argumentos de cada proceso
5. cmdscan        → historial de comandos en memoria
6. netscan        → conexiones de red
7. dlllist/dlldump → DLLs de procesos sospechosos
8. hashdump       → extraer hashes NTLM
9. shutdowntime   → cuándo se apagó el sistema
10. memdump/procdump → volcar proceso sospechoso para análisis
```
