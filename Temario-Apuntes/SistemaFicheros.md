# Sistemas de Ficheros
## D1n0 - Alejandro Mamán

Apuntes de sistemas de ficheros (FAT, NTFS/`$MFT`) surgidos del análisis forense práctico del Sherlock de HTB **BFT** (forense de `$MFT`, ver `~/Proyectos/HTB/BFT/BFTProgress.md` para el caso completo aplicado). Complementa `Forense-ReferenciaRapida.md` (rutas de artefactos que viven dentro de NTFS) y `Tema3-cheatsheet.md` (artefactos no volátiles de Windows).

---

## FAT (File Allocation Table)

Sistema de ficheros usado por FAT16/FAT32/exFAT. Estructura basada en una tabla de asignación:

- Al principio del volumen hay una tabla con una entrada por cada **clúster** del disco (unidad mínima de asignación, ej. 4KB).
- Cada entrada indica a qué fichero pertenece ese clúster y cuál es el siguiente clúster de ese mismo fichero (lista enlazada), o marca fin de fichero.
- La estructura de carpetas (el árbol de directorios) es independiente de la FAT: son entradas de directorio que apuntan al primer clúster del fichero, y a partir de ahí se sigue la cadena en la FAT.
- **El tamaño máximo de volumen direccionable depende del número de bits de cada entrada de la tabla**: FAT16 usa entradas de 16 bits (máx. ~65.536 clústeres → pocos GB), FAT32 usa 28 bits útiles (hasta ~2TB). De ahí el nombre FAT16/FAT32.

---

## NTFS - Diseño general

NTFS no usa FAT. En su lugar usa el **`$MFT` (Master File Table)**: una tabla con una entrada por fichero/carpeta (no por clúster), y cada entrada guarda dónde están sus datos (o los datos mismos, si el fichero es pequeño). Direcciona clústeres con números de 64 bits, sin el límite práctico de tamaño que tenía FAT16/32.

### Origen del `$MFT`

- Es parte del propio NTFS: se crea automáticamente al formatear un volumen con NTFS, no lo instala ningún programa.
- Vive en la raíz del volumen (`C:\$MFT`), pero está oculto y bloqueado por el sistema operativo mientras está en uso (no se puede copiar directamente con el Explorador).
- Su ubicación exacta (en qué clúster empieza) está anotada en el **sector de arranque** del volumen.
- Crece dinámicamente: cada fichero/carpeta nuevo añade una entrada nueva.

### Cómo extraer el `$MFT` de una máquina real (adquisición forense)

Dos vías típicas para un analista:
1. **Copia en caliente** (máquina encendida): herramientas como **KAPE** o **FTK Imager** acceden al disco a bajo nivel, saltándose el bloqueo del sistema operativo, y extraen el fichero tal cual.
2. **Imagen completa del disco** (offline): se clona el disco bit a bit y luego se extrae el `$MFT` de esa copia con calma.

### Estructura de un registro (record) del `$MFT`

- Tamaño de registro **fijo: 1024 bytes**. El registro nº `N` ocupa los bytes `[N*1024, N*1024+1023]` del fichero `$MFT`. El "record number" / "entry number" es su índice en ese array.
- Los primeros registros están reservados para ficheros de sistema (registro 0 = `$MFT` mismo, registro 1 = `$MFTMirr`...). **El registro número 5 es siempre la carpeta raíz del volumen** (convención fija de NTFS).
- Cada registro tiene una cabecera fija:
  - Bytes 0-3: firma `FILE` (si no está, el registro está corrupto o vacío).
  - Bytes 4-5: offset donde empieza el USA (ver fixup, más abajo).
  - Bytes 6-7: número de valores del USA.
  - Bytes 16-17: sequence number.
  - Bytes 20-21: `first_attr_offset` - offset donde empieza el primer atributo.
  - Bytes 24-27: `bytes_in_use`.
  - Bytes 28-31: `bytes_allocated` (normalmente 1024, confirma el tamaño de registro).
- Tras la cabecera, una lista de **atributos** uno detrás de otro hasta un marcador de fin (`0xFFFFFFFF`).

### Atributos de un registro

Cada atributo tiene: tipo (4 bytes), longitud total (4 bytes, para saltar al siguiente), flag resident/non-resident, y si es resident, tamaño y offset del contenido.

| Tipo (hex) | Nombre | Contenido |
|---|---|---|
| `0x10` | `$STANDARD_INFORMATION` | Timestamps que ve el Explorador de Windows, permisos. **Fácil de modificar** (cualquier API que toque fechas de un fichero escribe aquí). |
| `0x30` | `$FILE_NAME` | Nombre del fichero, número de registro del padre, y **otra copia independiente** de los timestamps, mantenida por el propio sistema de ficheros al crear/mover el fichero. **Mucho más difícil de falsificar** que la de `$STANDARD_INFORMATION`. |
| `0x80` | `$DATA` | Contenido del fichero. Puede haber **varios** `$DATA` en un mismo registro: uno sin nombre (contenido normal) y otros con nombre (Alternate Data Streams, ADS - ej. `Zone.Identifier`). |

**Timestamps MACB:** cada bloque de timestamps (tanto en `$STANDARD_INFORMATION` como en `$FILE_NAME`) trae Modified, Accessed, Changed (MFT entry modified) y Born/Creation. Comparar `$Created0x10` (SI) contra `$Created0x30` (FN) es una técnica clásica para detectar **timestomping** (manipulación de fechas): si no coinciden, alguien probablemente reescribió la fecha visible (SI) con una herramienta, sin poder tocar la copia de FN.

### Resident vs non-resident data

- **Resident**: el contenido del atributo (típicamente `$DATA`) va pegado dentro del propio registro de 1024 bytes, si es lo bastante pequeño. Se puede leer directamente del `$MFT`, sin acceso al resto del disco.
- **Non-resident**: el registro solo guarda punteros (VCN - Virtual Cluster Number) a dónde están los clústeres reales del fichero en el resto del volumen. Necesario para ficheros grandes.
- Implicación forense: un fichero pequeño (script, ejecutable minúsculo) borrado del disco puede seguir siendo recuperable **con su contenido íntegro** con solo tener el `$MFT`, si su `$DATA` era resident.

### Alternate Data Streams (ADS) - `Zone.Identifier`

Windows añade automáticamente un stream `$DATA` con nombre `Zone.Identifier` a cualquier fichero descargado de internet ("Mark of the Web"). Contenido típico (texto plano, resident):
```
[ZoneTransfer]
ZoneId=3
ReferrerUrl=<ruta o URL de origen>
HostUrl=<URL exacta de descarga>
```
- `ZoneId=3` = zona "Internet".
- `HostUrl` es un IOC de alto valor: revela la URL exacta desde la que se descargó el fichero.
- `ReferrerUrl` puede ser una ruta local si el fichero salió de extraer otro ZIP (herencia del MOTW en cascada).

### El "fixup" (Update Sequence Array, USA)

Mecanismo de integridad de NTFS, no relacionado con seguridad ofensiva:

- **Problema que resuelve:** un registro de 1024 bytes ocupa 2 sectores de disco de 512 bytes. Si el sistema se apaga a mitad de una escritura, podría quedar un sector actualizado y otro no, sin forma de detectarlo.
- **Solución:** antes de escribir el registro, NTFS coge los **últimos 2 bytes de cada sector de 512 bytes**, los guarda aparte en un array al principio del registro (el USA), y en su lugar escribe una firma de comprobación de 2 bytes (igual en todos los sectores del registro).
- Al leer: si esos 2 bytes al final de cada sector coinciden con la firma esperada, el sector se escribió completo.
- **Para leer el contenido real hay que deshacer esto**: sustituir esos 2 bytes de firma (en las posiciones 510-511 y 1022-1023 de un registro de 1024 bytes) por los valores reales guardados en el USA. Si no se hace, un hex editor muestra esos bytes como corruptos/incorrectos.

### Indicadores forenses típicos sobre el `$MFT`

- **Timestomping:** discrepancia entre `$Created0x10` (SI) y `$Created0x30` (FN).
- **Fecha epoch 1980-01-01:** valor por defecto que Windows asigna cuando un fichero se extrae de un `.zip` sin timestamp válido en la entrada - indica que el fichero vino de dentro de un ZIP.
- **Ejecutables/scripts fuera de rutas de sistema habituales** (`Windows\`, `Program Files\`...): más sospechosos por defecto que en su ubicación esperada.
- **Cadenas de zips anidados** (zip dentro de zip dentro de zip): técnica para evadir escaneo de antivirus en el correo/descarga. Detectable porque al extraer un zip con el Explorador se crea una carpeta hermana con su mismo nombre sin extensión - patrón mecánico buscable en todo el `$MFT`.

---

## Herramientas de análisis de `$MFT`

- **MFTECmd** (Eric Zimmerman, Windows/.NET) - parsea el `$MFT` crudo a CSV/JSON/etc.
- **analyzeMFT** (Python, multiplataforma) - equivalente funcional. Limitaciones observadas en la práctica:
  - No resuelve rutas completas (solo da `Parent Record Number`, hay que reconstruir la ruta subiendo la cadena de padres a mano).
  - Si un registro tiene varios atributos del mismo tipo (ej. dos `$DATA`), los guarda en un diccionario por tipo y el último sobreescribe al anterior en el CSV - se puede perder el contenido real de un fichero si tiene un ADS además del `$DATA` principal. Para recuperar ambos hay que parsear el registro crudo a mano.
- **TimeLine Explorer** / **visidata** (Linux) - filtrado y análisis del CSV resultante.
- **HxD** / **ghex** / **ImHex** (Linux) - inspección hexadecimal directa del `$MFT` para recuperar contenido resident.
