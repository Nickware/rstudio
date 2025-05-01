#!/bin/bash
# Instalador de RStudio para distribuciones Fedora
# Este script instala paquetes esenciales de R, RStudio Desktop 
# Requiere privilegios de superusuario para instalar paquetes
# Este script ha sido probado en Fedora 41
# Versión 2.2 - 30/04/2025
# Autor: N.Torres

# Función para verificar si un comando se ejecutó correctamente
# Si el comando anterior falló (código de salida distinto de 0), muestra un mensaje de error y termina el script.
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 falló. Abortando."
        exit 1
    fi
}

# Habilitar el repositorio COPR para RStudio
# Este repositorio contiene los paquetes necesarios para instalar RStudio.
echo "Habilitando el repositorio COPR para RStudio..."
sudo dnf copr enable iucar/rstudio -y
check_command "Habilitación del repositorio COPR"

# Instalar RStudio Desktop
# Descarga e instala la versión de escritorio de RStudio.
echo "Instalando RStudio Desktop..."
sudo dnf install rstudio-desktop -y
check_command "Instalación de RStudio Desktop"

# Instalar RStudio Server
# Descarga e instala la versión de servidor de RStudio.
echo "Instalando RStudio Server..."
sudo dnf install rstudio-server -y
check_command "Instalación de RStudio Server"

# Instalar paquetes esenciales de R
# Utiliza R para instalar paquetes populares como shiny, dplyr, ggplot2, etc.
echo "Instalando paquetes esenciales de R..."
sudo R --vanilla <<EOF
install.packages(c('shiny', 'shinydashboard', 'dplyr', 'ggplot2', 'tidyr'), repos='https://cloud.r-project.org/')
EOF
check_command "Instalación de paquetes de R"

# Mensaje final indicando que la instalación se completó con éxito.
echo "Instalación completada con éxito. ¡RStudio está listo para usar!"
