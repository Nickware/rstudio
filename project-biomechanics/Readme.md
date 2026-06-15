
# Running Biomechanics Analysis Platform

## Descripción del Proyecto

Aplicación científica en R-Shiny para análisis longitudinal de biomecánica y fisiología del running. El estudio compara sesiones en cinta y asfalto durante 16 semanas, evaluando la hipótesis de que el corredor evoluciona desde un régimen oscilatorio hacia un régimen estable (sistema dinámico amortiguado).

**Características principales:**
- Ingesta de datos Garmin (actividades individuales y colectivas)
- Detección automática de estructura de archivos
- Normalización de datos biomecánicos
- Análisis longitudinal y modelos mixtos
- Modelado de oscilador amortiguado
- Visualizaciones interactivas

---

## Requisitos del Sistema

| Componente | Versión Mínima | Recomendada |
|------------|---------------|--------------|
| **Sistema Operativo** | Linux (Ubuntu/Debian/Deepin) | Ubuntu 22.04 LTS |
| **R** | 4.0.0 | 4.3.0+ |
| **RStudio** | 2022.12 | 2024.12+ |
| **Memoria RAM** | 4 GB | 8 GB+ |
| **Espacio en disco** | 2 GB | 5 GB |

---

## Instalación en Deepin 25 (Recomendado)

Deepin 25 tiene características de inmutabilidad. Se recomienda usar **Distrobox** para evitar conflictos de dependencias.

### Paso 1: Instalar Distrobox

```bash
sudo apt update
sudo apt install distrobox podman
```

### Paso 2: Crear contenedor con Ubuntu 22.04

```bash
distrobox create --name r-running --image ubuntu:22.04
distrobox enter r-running
```

### Paso 3: Instalar R y RStudio dentro del contenedor

```bash
# Actualizar repositorios
sudo apt update

# Instalar R base y herramientas
sudo apt install -y r-base r-base-dev

# Descargar e instalar RStudio
wget https://download1.rstudio.org/electron/jammy/amd64/rstudio-2024.12.0-467-amd64.deb
sudo dpkg -i rstudio-*.deb
sudo apt install -f
```

---

## Instalación en Ubuntu/Debian (Instalación Directa)

Si no usa Deepin o prefiere instalación directa:

### Paso 1: Agregar repositorio CRAN (para versión actualizada)

```bash
# Agregar clave GPG
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc

# Agregar repositorio (para Ubuntu 22.04)
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/"
```

### Paso 2: Instalar R

```bash
sudo apt update
sudo apt install -y r-base r-base-dev
```

### Paso 3: Instalar RStudio

```bash
# Descargar desde sitio oficial
wget https://download1.rstudio.org/electron/jammy/amd64/rstudio-2024.12.0-467-amd64.deb

# Instalar
sudo dpkg -i rstudio-*.deb
sudo apt install -f
```

---

## Dependencias del Sistema (Bibliotecas necesarias)

**IMPORTANTE:** Ejecutar este comando **completo** para instalar todas las bibliotecas que R necesita para compilar paquetes:

```bash
sudo apt update
sudo apt install -y \
    build-essential \
    libuv1-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libgit2-dev \
    libssh2-1-dev \
    libudev-dev \
    libicu-dev \
    libpq-dev \
    libsqlite3-dev \
    libmariadb-dev \
    libv8-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libharfbuzz-icu-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libxt-dev \
    libx11-dev \
    libxext-dev \
    libasound2-dev \
    libnss3-dev \
    pkg-config
```

### Verificación de dependencias instaladas

```bash
# Verificar bibliotecas críticas
pkg-config --modversion freetype2
pkg-config --modversion harfbuzz
pkg-config --modversion libxml-2.0
pkg-config --modversion libcurl
```

---

## Instalación de Paquetes de R

### Iniciar R

```bash
R
```

### Paquetes Base (Obligatorios)

```r
# Instalar paquetes esenciales
install.packages(c(
    "shiny",
    "shinydashboard",
    "shinyjs",
    "tidyverse",
    "DT",
    "ggplot2",
    "plotly"
))
```

### Paquetes para Modelado Científico

```r
# Modelado de sistemas dinámicos (oscilador amortiguado)
install.packages(c(
    "deSolve",
    "optimx"
))

# Análisis longitudinal
install.packages(c(
    "lme4",
    "nlme",
    "mgcv"
))
```

### Paquetes para Procesamiento de Señales

```r
# Procesamiento de series temporales
install.packages(c(
    "signal",
    "zoo",
    "imputeTS"
))
```

### Paquetes para Reportes

```r
# Generación de reportes
install.packages(c(
    "rmarkdown",
    "knitr",
    "officer"
))
```

### Verificación de instalación

```r
# Lista completa de paquetes necesarios para el proyecto
paquetes_necesarios <- c(
    "shiny", "shinydashboard", "shinyjs", "tidyverse", "DT",
    "ggplot2", "plotly", "deSolve", "lme4", "mgcv",
    "signal", "zoo", "rmarkdown"
)

# Verificar instalación
for(pkg in paquetes_necesarios) {
    if(require(pkg, character.only = TRUE)) {
        cat("✅", pkg, "instalado\n")
    } else {
        cat("❌", pkg, "NO instalado\n")
    }
}
```

---

## Estructura del Proyecto

```
running_app/
├── app.R                       # Punto de entrada de la aplicación
├── R/
│   ├── schemas.R               # Definición de esquemas de datos
│   └── detector_tipo.R         # Detección de tipo de archivo y normalización
├── modules/
│   ├── data_import_ui.R        # UI del módulo de ingesta
│   └── data_import_server.R    # Server del módulo de ingesta
├── data/
│   ├── raw/                    # Datos crudos (no versionados)
│   └── processed/              # Datos procesados
├── reports/                    # Reportes generados
└── www/                        # Archivos estáticos (CSS, JS)
```

---

## Ejecución de la Aplicación

### Desde RStudio
1. Abrir `app.R`
2. Hacer clic en **Run App**

### Desde Terminal

```bash
cd /ruta/a/running_app
R -e "shiny::runApp('app.R', port=3535, host='0.0.0.0')"
```

### Acceso desde navegador
- Local: `http://127.0.0.1:3535`
- Remoto: `http://[IP-del-servidor]:3535`

---

## Estructuras de Datos Esperadas

### Archivo Individual (44 columnas)
Columnas principales requeridas:
- `Vueltas`, `Tiempo`, `Distancia`, `Ritmo.medio`
- `Frecuencia.cardiaca.media`, `Cadencia.de.carrera.media`
- `Tiempo.medio.de.contacto.con.el.suelo`
- `Longitud.media.de.zancada`

### Archivo Colectivo (36 columnas)
Columnas principales requeridas:
- `Tipo de actividad`, `Fecha`, `Distancia`
- `Frecuencia cardiaca media`, `Cadencia de carrera media`
- `Tiempo medio de contacto con el suelo`

---

## Solución de Problemas Comunes

### Error: `libnss3.so: cannot open shared object file`

```bash
sudo apt install libnss3-dev
```

### Error: `libasound.so.2: cannot open`

```bash
sudo apt install libasound2-dev
```

### Error: `curl/curl.h: No such file`

```bash
sudo apt install libcurl4-openssl-dev
```

### Error: `fontconfig/fontconfig.h: No such file`

```bash
sudo apt install libfontconfig1-dev
```

### Error: `hb-ft.h: No such file`

```bash
sudo apt install libharfbuzz-dev
```

### Error: `ft2build.h: No such file`

```bash
sudo ln -s /usr/include/freetype2/ft2build.h /usr/include/ft2build.h
sudo ln -s /usr/include/freetype2/freetype /usr/include/freetype
```

---

## Verificación Final

Ejecuta este script para confirmar que todo está correcto:

```r
# test_environment.R
library(shiny)
library(shinydashboard)
library(tidyverse)
library(deSolve)
library(ggplot2)

# Probar Shiny
runExample("01_hello")

# Probar deSolve (oscilador)
library(deSolve)
oscillator <- function(t, state, parms) {
  with(as.list(c(state, parms)), {
    dx <- v
    dv <- -k*x - c*v
    list(c(dx, dv))
  })
}
state <- c(x = 1, v = 0)
parms <- c(k = 10, c = 0.5)
times <- seq(0, 10, by = 0.01)
out <- ode(y = state, times = times, func = oscillator, parms = parms)

# Graficar
plot(out[, "time"], out[, "x"], type = "l", 
     main = "Oscilador amortiguado - Funciona!")

cat("\n Entorno configurado correctamente\n")
```

---

## Soporte

Si encuentra problemas durante la instalación:

1. Verificar la versión de R: `R --version`
2. Verificar dependencias del sistema: `apt list --installed | grep -E "lib(uv|xml|curl|fontconfig|harfbuzz|freetype)"`
3. Revisar los logs de R para errores específicos

---

## Licencia

Este proyecto es de uso académico y científico para el análisis de la biomecánica del running.

---

**Última actualización:** junio 2026
