#!/bin/bash
# Instalador de RStudio 
# Este script instala paquetes esenciales de R, RStudio Desktop 
# Requiere privilegios de superusuario para instalar paquetes
# Este script ha sido probado en Deepin 23.1
# Versión 2.2 - 30/04/2025
# Autor: N.Torres

# Función para verificar si un comando se ejecutó correctamente
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 falló. Abortando."
        exit 1
    fi
}

echo "Actualizando los repositorios..."
sudo apt update && sudo apt upgrade -y
check_command "Actualización del sistema"

echo "Instalando dependencias necesarias..."
sudo apt install -y gdebi-core wget r-base
check_command "Instalación de dependencias"

# Solicitar al usuario que proporcione la URL del paquete .deb
echo "Por favor, visite la página oficial de RStudio Desktop:"
echo "https://posit.co/download/rstudio-desktop/"
echo "Busque el paquete .deb correspondiente a su arquitectura."
read -p "Pegue aquí la URL del paquete .deb: " download_url

if [[ -z "$download_url" ]]; then
    echo "Error: No se proporcionó una URL. Abortando."
    exit 1
fi

echo "Descargando RStudio Desktop desde $download_url..."
wget "$download_url" -O rstudio-desktop.deb
check_command "Descarga de RStudio Desktop"

echo "Instalando RStudio Desktop..."
sudo gdebi -n rstudio-desktop.deb
check_command "Instalación de RStudio Desktop"

# Generar log de instalación
log_file="install_log_$(date +%Y%m%d_%H%M%S).txt"
echo "Generando log de instalación en $log_file..."
{
    echo "Fecha de instalación: $(date)"
    echo "Software instalado:"
    echo "- RStudio Desktop"
    echo "Complementos instalados:"
    dpkg -l | grep -E 'gdebi|wget|r-base|rstudio'
} > "$log_file"
check_command "Generación del log de instalación"

echo "Instalación completada. Detalles registrados en $log_file."
