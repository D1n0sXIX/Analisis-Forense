# Cheatsheet Tema 1 — Forense
## D1n0 - Alejandro Mamán

---

## Cadena de Custodia (FTK Imager)

### Estructura de directorios del caso
```
CasoXXX/
├── Evidencia-Original/   ← archivo original, NO tocar
├── Hashes/               ← hash-original.csv + hash-working.csv
├── Working/              ← copia de la evidencia original
└── Analisis/             ← copia de Working/ → aquí trabajamos
```

### Flujo paso a paso
```
1. FTK Imager → "Export File Hash List"  →  guardar como hash-original.csv en Hashes/
2. FTK Imager → "Export File"            →  copiar evidencia a Working/
3. FTK Imager → "Export File Hash List"  →  guardar como hash-working.csv en Hashes/
4. Comparar hashes (ver abajo)           →  verificar integridad
5. Copiar Working/ → Analisis/           →  trabajar siempre sobre Analisis/
```

> FTK Imager **no compara listas de hashes entre sí**, solo las genera.  
> La comparación hay que hacerla manualmente con HashCalc (Windows) o en Linux.

### Comparar hashes en Linux (fiable y estándar)
```bash
# Comparar los dos CSV exportados por FTK
diff hash-original.csv hash-working.csv
# Sin output = idénticos = integridad OK

# Si los hashes están en ficheros de texto plano (uno por línea)
md5sum -c hash-original.txt    # verifica cada hash contra su fichero

# Comparar un hash concreto manualmente
md5sum Working/evidencia.dd
# Comparar visualmente con el valor en hash-original.csv
```

---

## Metadatos

### Metagoofil — metadatos de archivos asociados a un dominio
```bash
# Buscar y descargar ficheros de un dominio extrayendo sus metadatos
metagoofil -d ejemplo.com -t pdf,doc,xls -o /salida/

# Limitar número de ficheros descargados
metagoofil -d ejemplo.com -t pdf -l 20 -o /salida/
```
| Flag | Significado |
|------|-------------|
| `-d` | Dominio objetivo |
| `-t` | Tipos de fichero (pdf, doc, xls, ppt...) |
| `-l` | Límite de ficheros a descargar |
| `-o` | Carpeta de salida |

> Útil en OSINT/reconocimiento: puede revelar usuarios, rutas internas, software usado.

### exiftool — metadatos de cualquier fichero
```bash
# Ver todos los metadatos
exiftool fichero.jpg

# Campos concretos
exiftool -Author -CreateDate -GPSLatitude fichero.jpg

# Recursivo en carpeta
exiftool -r carpeta/

# Exportar a CSV
exiftool -csv *.jpg > metadatos.csv

# Eliminar todos los metadatos (solo en copia, nunca en original)
exiftool -all= fichero.jpg

# Detectar si el fichero es lo que parece (extensión vs tipo real)
exiftool -FileType -MIMEType sospechoso.xxx
```

---

##  Password Cracking — Flujo Completo

---

### PASO 1 — Identificar qué tienes y extraer el hash

```bash
# ZIP cifrado
zip2john fichero.zip > hash.txt

# RAR cifrado
rar2john fichero.rar > hash.txt

# Fichero genérico / hash suelto → identificar tipo
hash-identifier                         # pegar el hash cuando lo pida
hashid "5f4dcc3b5aa765d61d8327deb882cf99"

# Ver el hash generado (para saber el formato)
cat hash.txt
```

| Longitud / Patrón | Tipo probable |
|-------------------|---------------|
| 32 hex | MD5 |
| 40 hex | SHA1 |
| 64 hex | SHA256 |
| `$1$...` | MD5-crypt Linux |
| `$6$...` | SHA512-crypt Linux |
| `$zip2$...` | ZIP (john) |

---

### PASO 2 — Elegir/generar el diccionario

#### Opción A — Usar rockyou directamente
```bash
# Ya disponible en Kali
/usr/share/wordlists/rockyou.txt
```

#### Opción B — Generar diccionario con crunch (fuerza bruta por patrón)
```bash
# Todas las combinaciones de 6 chars con letras y números
crunch 6 6 abcdefghijklmnopqrstuvwxyz0123456789 -o wordlist.txt

# Patrón fijo: 4 letras minúsculas + 2 dígitos
crunch 6 6 -t ????%%  -o wordlist.txt
# @ = minúscula  ,  % = dígito  ,  ^ = símbolo  ,  , = mayúscula

# Variaciones de una palabra base (ej: si sabes que la pass empieza por "cisco")
crunch 8 8 -t cisco%%% -o wordlist.txt    # cisco + 3 dígitos
```

#### Opción C — Generar diccionario con CeWL (desde una web)
```bash
# Extraer palabras de una web como base del diccionario
cewl -d 2 -m 6 http://target.com -w wordlist.txt
# -d = profundidad de crawling
# -m = longitud mínima de palabra

# Incluir números
cewl -d 2 --with-numbers http://target.com -w wordlist.txt
```
> Útil cuando sabes que la contraseña está relacionada con el contexto del caso (empresa, web, nombre...).

#### Opción D — Generar diccionario con kwprocessor (patrones de teclado)
```bash
# Windows
kwp64.exe basechars\tiny.base keymaps\es.keymap routes\2-to-10-max-2-direction-changes-combinator.route -o keywalk.txt

# Genera duplicados → limpiar antes de usar
sort -u keywalk.txt -o keywalk_clean.txt
```
> Útil para contraseñas tipo `qwerty`, `1qaz2wsx`, `asdfgh`.

---

### PASO 3 — Crackear

#### Con John the Ripper

```bash
# Ataque por diccionario simple
john --wordlist=rockyou.txt hash.txt

# Ataque por diccionario + reglas de mutación (añade mayúsculas, números al final, leetspeak...)
john --wordlist=rockyou.txt --rules hash.txt

# Ataque híbrido: diccionario + máscara (ej: palabra + 2 dígitos al final)
john --wordlist=rockyou.txt --mask=?w?d?d hash.txt
# ?w = palabra del diccionario, ?d = dígito

# Especificar formato (necesario para ZIP, RAR...)
john --format=zip  --wordlist=rockyou.txt hash.txt
john --format=rar5 --wordlist=rockyou.txt hash.txt

# Listar formatos disponibles
john --list=formats | grep -i zip

# Ver contraseñas encontradas
john --show hash.txt
```

| Máscara john | Significado |
|---------|-------------|
| `?l` | Minúscula (a-z) |
| `?u` | Mayúscula (A-Z) |
| `?d` | Dígito (0-9) |
| `?s` | Símbolo |
| `?a` | Cualquier carácter |
| `?w` | Palabra del diccionario (híbrido) |

#### Con hashcat

```bash
# Ataque diccionario (-a 0)
hashcat -a 0 -m 13600 hash.txt rockyou.txt          # ZIP
hashcat -a 0 -m 12500 hash.txt rockyou.txt          # RAR3
hashcat -a 0 -m 0     hash.txt rockyou.txt          # MD5

# Ataque diccionario + reglas de mutación
hashcat -a 0 -m 0 hash.txt rockyou.txt -r /usr/share/hashcat/rules/best64.rule

# Ataque híbrido: diccionario + máscara al final (-a 6)
hashcat -a 6 -m 0 hash.txt rockyou.txt ?d?d         # palabra + 2 dígitos al final

# Ataque híbrido: máscara al inicio + diccionario (-a 7)
hashcat -a 7 -m 0 hash.txt ?d?d rockyou.txt         # 2 dígitos + palabra

# Ver resultados
hashcat -m 0 hash.txt --show
```

| `-m` | Tipo de hash |
|------|-------------|
| `0` | MD5 |
| `100` | SHA1 |
| `1400` | SHA256 |
| `1000` | NTLM (Windows) |
| `13600` | ZIP cifrado |
| `12500` | RAR3 |
| `13000` | RAR5 |

---

### PASO 4 — Usar la contraseña encontrada

```bash
# Descomprimir ZIP
unzip -P "contraseña" fichero.zip

# Descomprimir RAR
unrar x -p"contraseña" fichero.rar

# Si era un hash suelto → ya tienes la contraseña en texto claro en john --show
```

---

### Resumen visual del flujo

```
fichero cifrado
      │
      ▼
zip2john / rar2john / hash-identifier
      │
      ▼
¿Tengo pistas sobre la contraseña?
   ├── SÍ (web, contexto) → CeWL / crunch / kwprocessor → wordlist.txt
   └── NO                 → rockyou.txt directamente
      │
      ▼
john --wordlist=wordlist.txt [--rules] [--mask] hash.txt
      │  (o hashcat -a 0 / -a 6)
      ▼
john --show hash.txt  →  contraseña encontrada
      │
      ▼
unzip / unrar con la contraseña
```

---

##  Esteganografía — GIMP (análisis visual)

```
1. Abrir imagen en GIMP
2. Colores → Curvas → mover las curvas de cada canal (R, G, B)
   → Si hay un mensaje oculto, aparecerá al ajustar las curvas
3. Colores → Componentes → Descomponer → separar por canal RGBA
   → Ver cada canal por separado buscando texto o patrones
4. Colores → Niveles → ajustar punto negro/blanco
   → Puede revelar detalles en zonas muy oscuras o muy claras
```

> Si GIMP no revela nada visual, pasar a herramientas como `steghide`, `zsteg` o `binwalk`.
