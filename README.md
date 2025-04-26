# Instalador de RStudio para Debian/Ubuntu

Este script automatiza la instalación de RStudio Desktop en sistemas basados en Debian/Ubuntu. También incluye la instalación de paquetes esenciales de R para comenzar a trabajar con análisis de datos y desarrollo de aplicaciones Shiny.

## Requisitos previos

Antes de ejecutar el script, asegúrase de tener permisos de administrador (sudo) y una conexión a internet habilitada.

## Pasos para la instalación

1. **Ejecutar el script de instalación**:
   - Clonar este repositorio o descargar el script `install-rstudio-debian-users.sh`.
   - Hacer del script un archivo ejecutable:
     ```bash
     chmod +x install-rstudio-debian-users.sh
     ```
   - Ejecutar el script (recuerde debe ser con sudo):
     ```bash
     ./install-rstudio-debian-users.sh
     ```

2. **Proporcionar la URL del paquete `.deb`**:
    # Recuerde que el archivo que debe descargar, corresponde a un archivo .deb, asociado a las distribuciones Debian o sus distribuciones derivadas
   - Durante la ejecución, el script pedirá que visite la página oficial de RStudio Desktop: [https://posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/).
   - Debera busca el paquete `.deb` correspondiente a la arquitectura de su equipo (por ejemplo, `amd64`).
   - Copia la URL del paquete y pégala en la terminal cuando el script lo solicite.

3. **Instalación automática**:
   - El script descargará e instalará RStudio Desktop automáticamente.
   - También generará un archivo de log con los detalles de la instalación.

## Tareas posteriores a la instalación

Una vez que RStudio esté instalado correctamente, puede instalar paquetes esenciales de R ejecutando el siguiente comando:

```bash
echo "Instalando paquetes esenciales de R..."
sudo R --vanilla <<EOF
install.packages(c('shiny', 'shinydashboard', 'dplyr', 'ggplot2', 'tidyr'), repos='https://cloud.r-project.org/')
EOF
