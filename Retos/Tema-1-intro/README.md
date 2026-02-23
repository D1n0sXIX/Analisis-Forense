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
| `cat.jpg` | Imagen JPEG | 🔲 Pendiente |
| `PurpleThing.jpeg` | PNG camuflado como JPEG | ✅ Resuelto |
| `reto1` | Sin extensión — tipo desconocido | 🔲 Pendiente |
| `SuspectData.dd` | Volcado raw de dispositivo | 🔲 Pendiente |

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

## 🚩 Flags encontrados

| # | Flag | Ubicación | Técnica utilizada |
|---|---|---|---|
| 1 | `ABCTF{b1nw4lk_is_us3ful}` | `PurpleThing.jpeg` → imagen oculta tras IEND | foremost / binwalk |

---

## 🧰 Herramientas utilizadas

| Herramienta | Propósito |
|---|---|
| `exiftool` | Análisis de metadatos EXIF |
| `strings` | Extracción de cadenas legibles del binario |
| `steghide` | Detección de esteganografía clásica |
| `binwalk` | Detección y extracción de ficheros embebidos |
| `foremost` | Carving y extracción de ficheros por cabeceras |
| `xdg-open` | Visualización de ficheros desde terminal |
| `file` | Identificación del tipo real de un fichero |

---

## 🧰 Arsenal completo del reto

Herramientas conocidas y utilizadas a lo largo de toda la investigación:

| Herramienta | Categoría | Para qué sirve |
|---|---|---|
| `file` | Identificación | Revela el tipo real de un fichero independientemente de su extensión |
| `exiftool` | Metadatos | Extrae metadatos EXIF y detecta anomalías como trailer data |
| `strings` | Análisis binario | Muestra cadenas de texto legibles dentro de cualquier binario |
| `binwalk` | Análisis binario | Detecta y extrae ficheros embebidos dentro de otros ficheros |
| `foremost` | Carving | Recupera ficheros ocultos buscando sus cabeceras y footers |
| `steghide` | Esteganografía | Detecta y extrae datos ocultos en imágenes mediante esteganografía clásica |
| `xdg-open` | Visualización | Abre ficheros con la aplicación por defecto del sistema |

---

## 📌 Notas y pendientes

- [ ] Identificar tipo real de `reto1` con `file reto1`
- [ ] Analizar imágenes en busca de esteganografía (`steghide`, `binwalk`, `exiftool`)
- [ ] Montar o examinar `SuspectData.dd` (`fdisk -l`, `mount`, `autopsy`)
