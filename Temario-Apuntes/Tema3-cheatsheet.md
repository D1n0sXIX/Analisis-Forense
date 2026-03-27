# Cheatsheet Tema 3 — Windows II (Info No Volátil)
## D1n0 - Alejandro Mamán

---

## Introducción — Información No Volátil

La información **no volátil** persiste cuando se apaga o reinicia el equipo.
Incluye documentos, mails, ficheros borrados, historial de navegación, logs, registro, etc.
Se almacena principalmente en el **disco duro** (y sistemas de almacenamiento conectados).

> Contraposición: la info volátil (Tema 2) se pierde al apagar. La no volátil permanece en disco.

---

## Ficheros de Sistema Especiales

### hiberfil.sys — Fichero de Hibernación
- **Ubicación**: `C:\hiberfil.sys`
- Se crea cuando el equipo **hiberna**: vuelca toda la RAM al disco.
- Puede contener procesos, credenciales, artefactos de memoria.
- **Diferencia con Suspender**: suspender mantiene la RAM encendida (no genera fichero); hibernar la guarda en disco y apaga.

> Forensicamente muy valioso: equivale a un volcado de RAM de cuando se hibernó.

### pagefile.sys — Memoria Virtual
- **Ubicación**: `C:\pagefile.sys`
- Espacio en disco que el SO usa como extensión de la RAM.
- Almacena datos de **procesos inactivos** que no caben en RAM física.
- Puede contener procesos ocultos o datos de sesiones anteriores.

---

## Herramientas en el Arranque

### WhatInStartup (Nirsoft)
Muestra qué programas se ejecutan al inicio, con ruta, fecha de creación y origen en registro.

| Tipo | Clave de registro |
|------|-------------------|
| User Run | `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run` |
| Machine Run | `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run` |

### AutoRuns (Sysinternals)
Búsqueda exhaustiva en el registro de **todo lo que se ejecuta al arranque**.
- Incluye servicios, drivers, extensiones de shell, tareas programadas...
- Útil para detectar malware persistente.
- Destaca en amarillo entradas **sin firma digital** o sospechosas.

```
Claves de inicio al arranque/sesión:
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce
HKLM\Software\Microsoft\Windows\CurrentVersion\Run
HKCU\Software\Microsoft\Windows\CurrentVersion\Run
HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce
```

> `RunOnce` → se ejecuta una sola vez al inicio y se elimina. Usado por instaladores y malware.

---

## Registro de Windows

Base de datos jerárquica donde Windows almacena configuración del sistema, software, hardware y usuarios.
Se visualiza y edita con **Regedit** (nativo de Windows).

### Estructura — Las 5 Hives principales

| Hive | Abrev. | Contenido |
|------|--------|-----------|
| `HKEY_LOCAL_MACHINE` | HKLM | Configuración de todo el sistema (software, hardware, todos los usuarios) |
| `HKEY_CURRENT_USER` | HKCU | Configuración del usuario activo actualmente |
| `HKEY_USERS` | HKU | Perfiles de todos los usuarios cargados |
| `HKEY_CLASSES_ROOT` | HKCR | Asociaciones de extensiones de fichero ↔ programa por defecto |
| `HKEY_CURRENT_CONFIG` | HKCC | Perfil de hardware actual del equipo |

> Las actividades de usuario se graban mayoritariamente en `HKCU` y en el fichero `NTUSER.DAT`.

### Registro como log — LastWrite
Cada clave de registro almacena su **fecha de última modificación** (`LastWrite`).
Permite saber exactamente cuándo se instaló un programa, se conectó un USB, etc.

---

## Claves de Registro Forenses Clave

### Información del sistema

| Qué buscar | Ruta de registro |
|-----------|-----------------|
| Versión, service pack, fecha de instalación | `HKLM\Software\Microsoft\Windows NT\CurrentVersion` |
| Nombre del equipo (hostname) | `HKLM\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName` |
| Zona horaria (**¡IMP para el timeline!**) | `HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation` |
| Carpetas compartidas (shares) | `HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Shares` |
| Redes Wi-Fi utilizadas | `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\{GUID}` |
| SID de los usuarios | `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList` |

### Dispositivos USB conectados
```
HKLM\SYSTEM\CurrentControlSet\Enum\USBSTOR
```
- Contiene un registro de **cada USB conectado** (vendedor, producto, número de serie).
- Al conectar un USB, Windows busca el driver y crea esta clave.

```
HKLM\SYSTEM\MountedDevices
```
- Dispositivos que han sido **montados**, con la letra de unidad asignada.

### Actividad de usuario
```
HKCU  (o NTUSER.DAT offline)
```
- Accesos a carpetas (`ShellBags`)
- Ficheros abiertos recientemente (`RecentDocs`)
- Búsquedas en el explorador (`WordWheelQuery`)
- Claves `Run`/`RunOnce` del usuario

---

## Dispositivos Conectados

Windows almacena el historial de todos los dispositivos que han sido conectados.
Se puede ver en **Administrador de Dispositivos → Ver → Mostrar dispositivos ocultos**.

Los dispositivos portátiles (USBs) aparecen en la rama de "Dispositivos portátiles" aunque ya no estén conectados.

---

## Caché del Navegador, Cookies e Historial

> Aunque se borren, estos datos pueden permanecer en el **espacio sin asignar (unallocated)** del disco.

### Mozilla Firefox
| Artefacto | Ruta |
|-----------|------|
| Caché | `C:\Users\<usuario>\AppData\Local\Mozilla\Firefox\Profiles\XXXXXXX.default-release\cache2` |
| Cookies | `C:\Users\<usuario>\AppData\Roaming\Mozilla\Firefox\Profiles\XXXXXXX.default-release\cookies.sqlite` |
| Historial | `C:\Users\<usuario>\AppData\Roaming\Mozilla\Firefox\Profiles\XXXXXXX.default-release\places.sqlite` |

**Herramientas Nirsoft para Firefox:**
- `MZCacheView` → listar caché (URL, tipo de contenido, tamaño, fecha)
- `MZCookiesView` → extraer y visualizar todas las cookies
- `MZHistoryView` → extraer historial completo

> Los ficheros `.sqlite` se pueden abrir con **DB Browser for SQLite** para consultas SQL directas.

### Google Chrome
| Artefacto | Ruta |
|-----------|------|
| Caché | `C:\Users\<usuario>\AppData\Local\Google\Chrome\User Data\Default\Cache` |
| Historial y Cookies | `C:\Users\<usuario>\AppData\Local\Google\Chrome\User Data\Default` |

**Herramientas Nirsoft para Chrome:**
- `ChromeCacheView` → caché de Chrome
- `ChromeCookiesView` → cookies de Chrome
- `ChromeHistoryView` → historial de Chrome

### Microsoft Edge (Legacy / IE)
| Artefacto | Ruta | Herramienta |
|-----------|------|-------------|
| Caché | `C:\Users\<usuario>\AppData\Local\Microsoft\Windows\WebCache` | IECacheView |
| Cookies | `C:\Users\<usuario>\AppData\Local\Microsoft\Windows\INetCookies` | IECookiesView |
| Historial | `C:\Users\<usuario>\AppData\Local\Microsoft\Windows\History` | IEHistoryView |

> Edge moderno usa base de datos **ESE** en `AppData\Local\Packages\Microsoft.MicrosoftEdge_*\AC\MicrosoftEdge\User\Default\DataStore\Data\nouser1\*\DBStore\spartan.eb`

---

## Análisis de Ficheros Windows

### Thumbnails (Miniaturas)
- Windows guarda miniaturas de imágenes para no tener que recargar el original.
- **Fichero**: `thumbcache.db`
- **Ubicación**: `C:\Users\<usuario>\AppData\Local\Microsoft\Windows\Explorer`
- **Herramienta**: `Thumbcache Viewer` → extrae las miniaturas con sus checksums.

> Aunque se borre la imagen original, la miniatura puede seguir en thumbcache.db.

### Ficheros Prefetch
- Se crean la **primera vez** que se ejecuta un programa desde una ruta determinada.
- Contienen nombre del ejecutable, rutas de DLLs cargadas, número de ejecuciones y **última vez ejecutado**.
- **Extensión**: `.pf`
- **Ubicación**: `C:\Windows\Prefetch`
- **Herramienta**: `WinPrefetchView` (Nirsoft) → lista todos los prefetch con contador de ejecuciones y timestamps.

> Se pueden correlacionar con eventos del registro para saber qué usuario estaba logueado.

### ExecutedProgramsList (Nirsoft)
Extrae la lista de **ejecutables que han corrido** en el sistema a partir de múltiples fuentes (prefetch, registro, etc.).
Útil para demostrar que un programa se ejecutó aunque ya no esté en el sistema.

### ShellBags
Cada vez que se abre una carpeta en el Explorador, Windows registra esta acción en el registro.
Permite reconstruir qué carpetas visitó el usuario y **cuándo**.

**Claves de registro:**
```
USRCLASS.DAT\Local Settings\Software\Microsoft\Windows\Shell\Bags
NTUSER.DAT\Software\Microsoft\Windows\Shell\BagMRU
NTUSER.DAT\Software\Microsoft\Windows\Shell\Bags
```

**Herramienta**: `ShellBagsView` (Nirsoft) → muestra el historial de carpetas con fecha de última modificación.

> Incluso si el directorio ya no existe (ej: de un USB eliminado), el ShellBag puede permanecer.

### Accesos Directos (.lnk)
- Ficheros con extensión `.lnk` que apuntan a programas, ficheros, carpetas o dispositivos externos.
- Contienen: ruta del objetivo, timestamps (creación, modificación, acceso), tamaño del fichero, atributos.
- Se crean automáticamente en `%APPDATA%\Microsoft\Windows\Recent\` al abrir ficheros.

> Revelan que se accedió a un fichero aunque el fichero original ya no exista.

---

## Eventos de Windows

Los eventos son los **logs del sistema** donde se registra todo lo que ocurre en el equipo.
- Se almacenan en ficheros `.evtx` en `%SystemRoot%\System32\Winevt\Logs\`
- Tres tipos principales: **Aplicación**, **Sistema**, **Seguridad**.
- Herramienta nativa: **Visor de Eventos**.
- Herramienta CLI: `psloglist.exe` (Sysinternals).
- Herramienta automática: **Hayabusa** → analiza logs y genera alertas basadas en reglas Sigma.

### Campos por evento
`EventID` · `Categoría` · `Tipo` · `Hora` · `Nombre de usuario` · `Equipo` · `Datos específicos`

---

### EventIDs — Autenticación y Sesiones

| EventID | Descripción |
|---------|-------------|
| `4624` | Login exitoso |
| `4625` | Login fallido |
| `4634` | Cierre de sesión exitoso |
| `4647` | Cierre de sesión iniciado por el usuario |
| `4648` | Login con credenciales explícitas |
| `4672` | Login con privilegios de administrador |
| `4740` | Cuenta bloqueada (demasiados intentos fallidos) |
| `4767` | Cuenta desbloqueada |
| `4776` | Controlador de dominio validó credenciales |
| `4778` | Sesión de Escritorio Remoto reconectada |
| `4779` | Sesión de Escritorio Remoto desconectada |

### EventIDs — Gestión de Cuentas

| EventID | Descripción |
|---------|-------------|
| `4720` | Cuenta creada |
| `4722` | Cuenta habilitada |
| `4723` | Usuario cambió su propia contraseña |
| `4724` | Contraseña restablecida por admin |
| `4725` | Cuenta deshabilitada |
| `4726` | Cuenta eliminada |
| `4732` | Cuenta añadida a un grupo |
| `4733` | Cuenta eliminada de un grupo |
| `4738` | Cambio en la información de una cuenta |
| `4781` | Cuenta renombrada |

### EventIDs — Procesos, Sistema y Seguridad

| EventID | Descripción |
|---------|-------------|
| `4688` | Creación de un nuevo proceso |
| `4698` | Tarea programada creada |
| `4699` | Tarea programada eliminada |
| `4700` | Tarea programada habilitada |
| `4701` | Tarea programada deshabilitada |
| `4702` | Tarea programada modificada |
| `4719` | Política de auditoría del sistema cambiada |
| `1102` | Log de seguridad borrado |
| `6005` | Equipo encendido (servicio "Event Log" arrancado) |
| `6006` | Equipo apagado |

### EventIDs — Kerberos

| EventID | Descripción |
|---------|-------------|
| `4768` | Solicitud de TGT Kerberos |
| `4770` | Renovación de ticket de servicio Kerberos |
| `4771` | Fallo en autenticación previa Kerberos |

### EventIDs — Dispositivos USB

| EventID | Fuente | Descripción |
|---------|--------|-------------|
| `20001` / `20003` / `10000` | System | Primera vez que se conecta el USB |
| `10100` | System | Actualización del driver del USB |
| `112` | DeviceSetupManager | Timestamp de cada USB insertado |

---

### Tipos de Logon (campo dentro de EventID 4624/4625)

| Logon Type | Nombre | Descripción |
|-----------|--------|-------------|
| `2` | Interactive | Login local (teclado + pantalla) |
| `3` | Network | Login remoto vía red (SMB, etc.) |
| `4` | Batch | Tarea programada o script |
| `5` | Service | Servicio iniciado por SCM |
| `7` | Unlock | Desbloqueo de estación de trabajo |
| `8` | NetworkCleartext | Login de red con credenciales en texto claro |
| `9` | NewCredentials | Login con credenciales diferentes a las de la sesión |
| `10` | RemoteInteractive | RDP / Terminal Services |
| `11` | CachedInteractive | Login con credenciales cacheadas localmente |
| `12` | CachedRemoteInteractive | RDP + credenciales cacheadas |
| `13` | CachedUnlock | Desbloqueo con credenciales cacheadas |

---

### Subcódigos del EventID 4625 (login fallido)

| Código | Motivo del fallo |
|--------|-----------------|
| `0xC0000064` | El nombre de usuario no existe |
| `0xC000006A` | El usuario existe pero la contraseña es incorrecta |
| `0xC0000234` | Cuenta bloqueada |
| `0xC0000072` | Cuenta deshabilitada |
| `0xC0000071` | Contraseña expirada |
| `0xC000006F` | Login fuera del horario permitido |
| `0xC0000193` | Cuenta expirada |

---

### Identificar ataques comunes con EventIDs

| Ataque / Evento | Cómo detectarlo |
|----------------|-----------------|
| **Fuerza bruta** | Múltiples `4625` seguidos del mismo usuario; si tiene éxito, aparece un `4624` después |
| **Borrado de logs** | EventID `1102` (Security) |
| **Cambio de hora** | EventID `4616` en Security → afecta a todo el timeline |
| **Deshabilitación de auditoría** | EventID `4719` → señal de que el atacante intenta cubrir su rastro |
| **Encendido/apagado** | `6005` (encendido) / `6006` (apagado) |
| **USB insertado** | EventIDs `20001`, `20003`, `10000`, `112` |

---

### Recuperar eventos borrados — Bulk Extractor
```bash
# Recupera eventos borrados usando file carving
bulk_extractor.exe -E evtx -o output_directory input_file
```
Proyecto: https://github.com/simsong/bulk_extractor

---

### Hayabusa — Análisis automático de eventos
```bash
# Analiza una carpeta de ficheros .evtx y genera alertas
hayabusa.exe csv-timeline -d C:\Windows\System32\winevt\Logs -o timeline.csv

# Generar resumen
hayabusa.exe logon-summary -d C:\Windows\System32\winevt\Logs
```
- Basado en **reglas Sigma** → categoriza eventos por severidad (Critical/High/Medium/Low).
- Genera un timeline legible con los eventos más relevantes.

---

## Frameworks de Análisis Forense

Herramientas que automatizan la extracción de toda la información no volátil a partir de una imagen de disco.

### Autopsy
- Open source, multiplataforma.
- Analiza imágenes de disco (.dd, .E01, etc.).
- Extrae automáticamente: historial de navegación, ficheros recientes, prefetch, registro, timeline...
- Basado en **The Sleuth Kit**.

### OSForensics
- Windows. Interfaz más amigable.
- Extrae artefactos forenses, realiza búsquedas, genera timelines.
- Permite montar imágenes y navegar por el sistema de ficheros.

---

## Resumen de Artefactos y Rutas

| Artefacto | Ubicación / Clave | Herramienta |
|-----------|-------------------|-------------|
| Hibernate dump | `C:\hiberfil.sys` | Volatility, strings |
| Memoria virtual | `C:\pagefile.sys` | strings, análisis manual |
| Miniaturas | `C:\Users\<usr>\AppData\Local\Microsoft\Windows\Explorer\thumbcache.db` | Thumbcache Viewer |
| Prefetch | `C:\Windows\Prefetch\*.pf` | WinPrefetchView |
| Programas ejecutados | Prefetch + registro | ExecutedProgramsList |
| ShellBags (carpetas vistas) | `NTUSER.DAT\...\Shell\BagMRU` | ShellBagsView |
| Accesos directos | `%APPDATA%\Microsoft\Windows\Recent\*.lnk` | Windows Shell Link |
| Eventos | `%SystemRoot%\System32\Winevt\Logs\*.evtx` | Visor de Eventos, psloglist, Hayabusa |
| USB conectados | `HKLM\SYSTEM\CurrentControlSet\Enum\USBSTOR` | Regedit |
| Dispositivos montados | `HKLM\SYSTEM\MountedDevices` | Regedit |
| Wi-Fi usadas | `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles` | Regedit |
| Hostname | `HKLM\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName` | Regedit |
| Zona horaria | `HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation` | Regedit |
| Versión de Windows | `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion` | Regedit |
| Shares (carpetas compartidas) | `HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Shares` | Regedit |
| Caché Firefox | `AppData\Local\Mozilla\Firefox\Profiles\*\cache2` | MZCacheView |
| Cookies Firefox | `AppData\Roaming\Mozilla\Firefox\Profiles\*\cookies.sqlite` | MZCookiesView |
| Historial Firefox | `AppData\Roaming\Mozilla\Firefox\Profiles\*\places.sqlite` | MZHistoryView |
| Caché Chrome | `AppData\Local\Google\Chrome\User Data\Default\Cache` | ChromeCacheView |
| Historial Chrome | `AppData\Local\Google\Chrome\User Data\Default` | ChromeHistoryView |
| Inicio automático | `HKLM\...\Run`, `HKCU\...\Run` | AutoRuns, WhatInStartup |
