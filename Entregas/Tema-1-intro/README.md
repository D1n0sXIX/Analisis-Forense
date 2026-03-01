# 📓 Diario Forense — Tema 1: Intro

**Investigador:** Alex  
**Caso:** Reto 1 — Análisis de artefactos ocultos  
**Directorio de trabajo:** `~/AnalisisForense/Retos/Tema-1-intro`  
**Fecha de inicio:** 23/02/2026  
**Estado:** 🔍 Investigación abierta

---

## 🗂️ Artefactos identificados

| Archivo | Tipo aparente | Estado |
|---|---|---|
| `cat.jpg` | Imagen JPEG | ✅ Resuelto |
| `PurpleThing.jpeg` | PNG camuflado como JPEG | ✅ Resuelto |
| `reto1` | Sin extensión — tipo desconocido | 🔲 Pendiente |
| `SuspectData.dd` | Volcado raw de dispositivo FAT16 | 🔍 En progreso |

---

## 📅 Entradas del diario

### Entrada #1 — 23/02/2026 · Reconocimiento inicial

Al listar el contenido del directorio encontramos 4 artefactos. Observaciones iniciales:

- **`cat.jpg` / `PurpleThing.jpeg`** — Imágenes JPEG que podrían contener datos ocultos mediante esteganografía.
- **`reto1`** — Archivo sin extensión. Requiere identificación de tipo (`file`, `strings`, `hexdump`).
- **`SuspectData.dd`** — Volcado raw de disco en formato `.dd`. Alto interés forense: probablemente contiene un sistema de archivos montable con evidencias internas.

**Hipótesis inicial:** Combinación de esteganografía en imágenes y sistema de archivos oculto en el volcado de disco.

---

### Entrada #2 — 23/02/2026 · Análisis de PurpleThing.jpeg

Lo primero que hice fue abrirla visualmente — parecía una imagen normal, un Pac-Man morado. Nada sospechoso a simple vista:
```bash
xdg-open PurpleThing.jpeg
```
También la abrí con `nano` para ojear el contenido en bruto, pero sin resultados claros.

Siguiendo las recomendaciones de Claude, probé una serie de herramientas forenses:

**Con `exiftool`** descubrí la primera anomalía:
```bash
exiftool PurpleThing.jpeg
```
Aunque el fichero se llama `.jpeg`, en realidad es un **PNG**. Alguien le cambió la extensión deliberadamente para camuflarlo. Además, exiftool lanzó un warning muy revelador: `Trailer data after PNG IEND chunk`, lo que significa que hay datos escondidos **después del final oficial** de la imagen — el chunk `IEND` es el marcador de fin de un PNG, si hay algo después es porque fue puesto ahí a propósito.

**Con `steghide`** comprobé si había esteganografía clásica:
```bash
steghide info PurpleThing.jpeg
```
No encontró nada.

**Con `strings`** revisé las cadenas de texto en el binario:
```bash
strings PurpleThing.jpeg
```
Nada legible y relevante a simple vista.

**Con `binwalk`** confirmé la sospecha del warning de exiftool:
```bash
binwalk PurpleThing.jpeg
```
Dentro del fichero hay **dos imágenes PNG**:

```
Offset 0x00000  →  PNG #1  (780 × 720 px)  ← imagen visible (el Pac-Man)
                         [IEND] ← aquí debería terminar el fichero
Offset 0x25795  →  PNG #2  (802 × 118 px)  ← imagen OCULTA
```

**Para extraerlas** usé `foremost`, que busca ficheros por sus cabeceras y footers conocidos y los reconstruye correctamente:
```bash
foremost -i PurpleThing.jpeg
# -i : especifica el fichero de entrada a analizar
```
Esto creó la carpeta `output/png/` con dos ficheros:
- `00000000.png` — la imagen original (780×720), el Pac-Man morado
- `00000299.png` — la imagen oculta (802×118) — **aquí estaba el flag** ✅

> **Camino alternativo no explorado — `binwalk -e`:** habría extraído los datos pero en formato comprimido (`29` y `29.zlib`), los bloques zlib internos del PNG en bruto, requiriendo descompresión manual. También habría sido posible extraer por offset exacto con `dd if=PurpleThing.jpeg bs=1 skip=153493 of=hidden.png`. Se descartaron ambos al obtener resultado con foremost.

**Estado:** ✅ Resuelto

---

### Entrada #3 — 24/02/2026 · Análisis de cat.jpg

Lo primero fue abrirla visualmente — una foto de un gato, nada sospechoso:
```bash
xdg-open cat.jpg
```

**Con `exiftool`** revisé los metadatos:
```bash
exiftool cat.jpg
```
A diferencia de PurpleThing, aquí la extensión sí es correcta — es un JPEG real. Sin embargo, en los metadatos aparecieron campos sospechosos:
- `Copyright Notice` → `PicoCTF`
- `Rights` → `PicoCTF`
- `License` → `cGljb0NURnt0aGVfbTN0YWRhdGFfMXNfbW9kaWZpZWR9`

**PicoCTF** es una competición CTF famosa, claramente alguien metió ese texto a propósito. El campo `License` contenía una cadena de aspecto codificado.

Para intentar identificar el tipo de codificación guardé la cadena en un fichero y usé `hash-identifier`:
```bash
echo "cGljb0NURnt0aGVfbTN0YWRhdGFfMXNfbW9kaWZpZWR9" >> exiftoolCatCifrado.txt
hash-identifier exiftoolCatCifrado.txt
```
Resultado: `Not Found` — tiene sentido, ya que `hash-identifier` detecta hashes irreversibles (MD5, SHA...) pero Base64 es una codificación reversible, no un hash. Son cosas distintas:
- Un **hash** es irreversible (MD5, SHA256...)
- Una **codificación** como Base64 es reversible, no es cifrado real

Probé directamente con Base64:
```bash
echo "cGljb0NURnt0aGVfbTN0YWRhdGFfMXNfbW9kaWZpZWR9" | base64 -d
```
Y ahí apareció el flag. ✅

**Estado:** ✅ Resuelto

---

### Entrada #4 — 24/02/2026 · Análisis de SuspectData.dd

**Con `file` y `fdisk -l`** identifiqué el tipo de disco:
```bash
file SuspectData.dd
fdisk -l SuspectData.dd
```
Resultado: disco de **30 MiB**, sistema de archivos **FAT16**, tipo DOS/MBR, sin particiones — el sistema de archivos ocupa todo el disco desde el offset 0. Se puede montar directamente.

**Monté la imagen** para explorarla como un disco real:
```bash
sudo mkdir /mnt/suspectdata
sudo mount -o loop SuspectData.dd /mnt/suspectdata
ls /mnt/suspectdata
```
Contenido encontrado: varias imágenes de gatos y un fichero llamado `hello` sin extensión.

**El fichero `hello`** resultó ser el más interesante:
```bash
cat /mnt/suspectdata/hello
```
Mensaje: `Hello! You found some data! Well done! The Secret Code is "Let's go get some coffee"`.

**Analicé las imágenes** en busca de datos ocultos. Primero con `exiftool` sobre todos los ficheros — metadatos limpios, nada sospechoso. Luego con `steghide` usando la contraseña encontrada en `hello`, probando todas las imágenes con un bucle:
```bash
for img in /mnt/suspectdata/*.jpg /mnt/suspectdata/*.jpeg; do
    echo "Probando: $img"
    steghide extract -sf "$img" -p "Let's go get some coffee"
done
```
Ninguna imagen devolvió datos ocultos.

**Siguiente paso:** usar `foremost` sobre el volcado completo para intentar recuperar ficheros eliminados que no aparecen con `ls`.

**Estado:** 🔍 En progreso — pendiente de recuperación de ficheros eliminados

---

### Entrada #5 — [01/03/2026] · Análisis de reto1

**Con `file`** identifiqué el tipo de archivo:
```bash
file reto1
```
Resultado: `ELF 64-bit LSB pie executable, x86-64` — un ejecutable de Linux.

**Con `strings` y `grep`** busqué cadenas de texto que contuvieran "ctf":
```bash
strings reto1 | grep -i "ctf"
```
Entre el ruido apareció el flag claramente visible: `picoCTF{5tRIng5_1T_7f766a23}`

El nombre del flag ("strings it") confirma que la técnica correcta era usar `strings`.

**Estado:** ✅ Resuelto

---

### Entrada #6 — 01/03/2026 · Análisis de SuspectData.dd (continuación)

**Usé `foremost`** para recuperar ficheros eliminados:
```bash
foremost -i SuspectData.dd -o suspect_output
```
Recuperó 9 imágenes JPG. Analicé sus metadatos con `exiftool` — todos limpios. Probé `steghi>

**Intenté usar Autopsy** por recomendación de un compañero:
```bash
autopsy
```
Sin embargo, al intentar conectarme a `http://localhost:9999/autopsy` obtuve el error:
```
Can't open log: autopsy.log at /usr/share/autopsy/lib/Print.pm line 383.
```
Probé ejecutarlo con `sudo autopsy` pero no conseguí solucionar el problema. Decidí continua>

**Estado:** 🔍 En progreso

## 🚩 Flags encontrados

| # | Flag | Ubicación | Técnica utilizada |
|---|---|---|---|
| 1 | `ABCTF{b1nw4lk_is_us3ful}` | `PurpleThing.jpeg` → imagen oculta tras IEND | foremost / binwalk |
| 2 | `picoCTF{the_m3tadata_1s_modified}` | `cat.jpg` → campo License en metadatos EXIF | exiftool + base64 |
| ? | `The Secret Code is "Let's go get some coffee"` | `SuspectData.dd` → fichero `hello` | mount + cat |

---

## 🧰 Herramientas utilizadas

| Herramienta | Propósito |
|---|---|
| `exiftool` | Análisis de metadatos EXIF |
| `strings` | Extracción de cadenas legibles del binario |
| `steghide` | Detección de esteganografía clásica |
| `binwalk` | Detección de ficheros embebidos |
| `foremost` | Carving y extracción de ficheros por cabeceras |
| `xdg-open` | Visualización de ficheros desde terminal |
| `file` | Identificación del tipo real de un fichero |
| `hash-identifier` | Identificación de tipos de hash |
| `base64` | Decodificación de cadenas en Base64 |
| `fdisk` | Análisis de estructura de disco |
| `mount` | Montaje de imágenes de disco |

---

## 🧰 Arsenal completo del reto

Herramientas conocidas y utilizadas a lo largo de toda la investigación:

| Herramienta | Categoría | Para qué sirve |
|---|---|---|
| `file` | Identificación | Revela el tipo real de un fichero independientemente de su extensión |
| `exiftool` | Metadatos | Extrae metadatos EXIF y detecta anomalías como campos modificados |
| `strings` | Análisis binario | Muestra cadenas de texto legibles dentro de cualquier binario |
| `binwalk` | Análisis binario | Detecta ficheros embebidos dentro de otros ficheros |
| `foremost` | Carving | Recupera ficheros ocultos o eliminados buscando sus cabeceras y footers |
| `steghide` | Esteganografía | Detecta y extrae datos ocultos en imágenes mediante esteganografía clásica |
| `hash-identifier` | Criptoanálisis | Identifica el tipo de hash o codificación de una cadena |
| `base64` | Criptoanálisis | Codifica y decodifica cadenas en Base64 |
| `fdisk` | Análisis de disco | Muestra la estructura y particiones de una imagen de disco |
| `mount` | Análisis de disco | Monta imágenes de disco para explorarlas como sistemas de archivos reales |
| `xdg-open` | Visualización | Abre ficheros con la aplicación por defecto del sistema |

---

## 📌 Notas y pendientes

- [x] ~~Analizar imágenes en busca de datos ocultos~~
- [x] ~~Montar y explorar SuspectData.dd~~
- [ ] Recuperar ficheros eliminados de `SuspectData.dd` con `foremost`
- [ ] Identificar tipo real de `reto1` con `file reto1`
