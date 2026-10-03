# Instaladores de RStudio para Linux

Esta carpeta contiene dos scripts independientes para preparar entornos R en distribuciones Linux. El script de Debian/Ubuntu instala R y RStudio Desktop; el de Fedora instala RStudio Desktop y RStudio Server, y además intenta instalar paquetes de R. Lee las diferencias y los efectos sobre el sistema antes de ejecutar cualquiera de ellos.

## Qué instala cada script

| Script | Sistema objetivo | R | RStudio | Paquetes R |
|---|---|---|---|---|
| [`install-rstudio-debian-users.sh`](install-rstudio-debian-users.sh) | Debian/Ubuntu y derivados; probado según el script en Deepin 23.1 | Instala `r-base` | Descarga e instala RStudio Desktop desde un `.deb` indicado por el usuario | No los instala; se pueden añadir después con el comando de esta guía |
| [`install-rstudio.sh`](install-rstudio.sh) | Fedora; probado según el script en Fedora 41 | No instala R explícitamente; requiere que `R` esté disponible | Habilita COPR `iucar/rstudio` e instala RStudio Desktop y RStudio Server | Ejecuta `install.packages()` para `shiny`, `shinydashboard`, `dplyr`, `ggplot2` y `tidyr` |

R es el lenguaje y su entorno de ejecución. RStudio Desktop es un IDE gráfico y RStudio Server ofrece acceso al IDE mediante un servicio web. Los paquetes de R son bibliotecas que se instalan desde R, independientemente del IDE.

## Requisitos generales

- Una distribución compatible con uno de los scripts y conexión a Internet.
- Una cuenta con permisos para usar `sudo`.
- Para el script de Debian/Ubuntu, una arquitectura y un paquete `.deb` compatibles con el sistema.
- Para el script de Fedora, confirma que R esté instalado y que el repositorio COPR sea apropiado para tu versión de Fedora.

Los scripts invocan `sudo` en los comandos que modifican el sistema; ejecútalos como usuario normal desde una terminal. No es necesario anteponer `sudo` al propio script.

## Debian y Ubuntu

Desde la carpeta `rstudio-install`:

```bash
chmod +x install-rstudio-debian-users.sh
./install-rstudio-debian-users.sh
```

El script actualiza los índices de APT, ejecuta `apt upgrade -y`, instala `gdebi-core`, `wget` y `r-base`, y luego pide la URL del paquete `.deb` de RStudio Desktop. Obtén el enlace en la [página oficial de RStudio Desktop](https://posit.co/download/rstudio-desktop/) y comprueba que corresponda a tu distribución y arquitectura antes de pegarlo.

Ten en cuenta que `apt upgrade -y` puede actualizar otros paquetes del sistema, no solo los necesarios para RStudio. El `.deb` se descarga a `rstudio-desktop.deb` en el directorio actual y el script no verifica su suma de comprobación. Al terminar, se crea allí un archivo `install_log_*.txt` con información de paquetes instalados.

### Instalar paquetes de R (opcional)

El instalador Debian/Ubuntu no instala paquetes de R. Después de instalar R, abre una sesión de R como tu usuario y ejecuta:

```r
install.packages(
  c("shiny", "shinydashboard", "dplyr", "ggplot2", "tidyr"),
  repos = "https://cloud.r-project.org/"
)
```

En general, evita iniciar R como `root` para instalar bibliotecas personales. Si necesitas una instalación disponible para todos los usuarios, configura explícitamente una biblioteca de sistema y sus permisos.

## Fedora

Desde la carpeta `rstudio-install`:

```bash
chmod +x install-rstudio.sh
./install-rstudio.sh
```

El script habilita el repositorio COPR `iucar/rstudio`, instala `rstudio-desktop` y `rstudio-server`, y ejecuta `install.packages()` como `root` con los cinco paquetes indicados arriba. No contiene un paso explícito para instalar R; verifica antes que el comando `R` funcione en Fedora. Instalar RStudio Server también habilita software de servidor: revisa la configuración y seguridad de ese servicio antes de usarlo en un equipo accesible por red.

## Verificación

Después de la instalación, comprueba R y los paquetes desde una terminal:

```bash
R --version
Rscript -e 'sapply(c("shiny", "shinydashboard", "dplyr", "ggplot2", "tidyr"), requireNamespace, quietly = TRUE)'
```

En Debian/Ubuntu, la instalación de paquetes es opcional y el segundo comando puede mostrar `FALSE` hasta instalarlos. Para confirmar RStudio, inicia la aplicación desde el menú o ejecuta `rstudio` si el comando está disponible.

## Consideraciones

- Revisa el contenido del script antes de ejecutarlo: ambos realizan cambios a nivel de sistema.
- El script Debian/Ubuntu acepta una URL introducida por el usuario y no limita el dominio ni verifica el archivo descargado; utiliza únicamente un enlace confiable de Posit.
- El script Fedora habilita un repositorio de terceros y, además de Desktop, instala Server. Confirma que deseas ambos componentes.
- Estos scripts reflejan sus versiones y plataformas de prueba indicadas en sus comentarios; no garantizan compatibilidad con todas las versiones actuales de las distribuciones.
- La instalación de RStudio no instala automáticamente todas las dependencias del sistema que puedan requerir paquetes R adicionales.
