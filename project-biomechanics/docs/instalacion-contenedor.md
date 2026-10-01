# Entorno de desarrollo con Distrobox

Esta guía configura el proyecto en un contenedor Ubuntu 22.04 usando Distrobox y Podman. Es una opción útil en sistemas donde se prefiera aislar las dependencias, como Deepin. La app también puede ejecutarse con una instalación local de R; RStudio no es un requisito.

## 1. Instalar Distrobox y Podman en el anfitrión

En un anfitrión basado en Debian o Ubuntu:

```bash
sudo apt update
sudo apt install -y distrobox podman
```

## 2. Crear y abrir el contenedor

```bash
distrobox create --name r-running --image ubuntu:22.04
distrobox enter r-running
```

Los comandos siguientes se ejecutan dentro del contenedor. Distrobox comparte normalmente el directorio personal del usuario anfitrión; comprueba que la carpeta del repositorio esté disponible antes de iniciar la app.

## 3. Instalar R y dependencias del sistema

```bash
sudo apt update
sudo apt install -y \
  r-base \
  r-base-dev \
  build-essential \
  pkg-config \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libfontconfig1-dev \
  libfreetype6-dev \
  libfribidi-dev \
  libharfbuzz-dev \
  libpng-dev \
  libtiff-dev \
  libjpeg-dev \
  libcairo2-dev \
  libpango1.0-dev \
  libxt-dev
```

Estas bibliotecas cubren herramientas habituales de compilación para las dependencias gráficas y de red de R. Si la instalación de un paquete informa que falta una biblioteca del sistema, instala el paquete `-dev` correspondiente y vuelve a intentar la instalación.

## 4. Instalar los paquetes de R

Abre R dentro del contenedor:

```bash
R
```

En la consola de R, instala las dependencias utilizadas por la app:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "shinyjs",
  "tidyverse",
  "DT"
))
```

Sal de R con `q()` y confirma que R está disponible con `R --version`.

## 5. Ejecutar la aplicación

Dentro del contenedor, cambia al directorio del proyecto. Sustituye la ruta de ejemplo por la ubicación real del repositorio:

```bash
cd /ruta/al/repositorio/project-biomechanics
R -e "shiny::runApp('.', port = 3535)"
```

Abre `http://127.0.0.1:3535` en el navegador del anfitrión. Para detener la app, pulsa `Ctrl+C` en la terminal.

## RStudio (opcional)

La aplicación se puede desarrollar y ejecutar desde R sin instalar un IDE dentro del contenedor. Si se desea RStudio Desktop, descarga desde [Posit](https://posit.co/download/rstudio-desktop/) el paquete `.deb` actual compatible con Ubuntu 22.04 y la arquitectura del equipo. Dentro del contenedor, instala el archivo descargado con:

```bash
sudo apt install ./rstudio-*.deb
```

Luego inicia `rstudio` dentro del contenedor. La integración de ventanas gráficas depende de la configuración del anfitrión.

## Administración del contenedor

Para volver a entrar en una sesión posterior:

```bash
distrobox enter r-running
```

Para detener el contenedor desde el anfitrión:

```bash
distrobox stop r-running
```