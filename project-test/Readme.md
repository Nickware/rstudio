# Baloto Analyzer

Aplicación exploratoria en R y Shiny para consultar resultados históricos de Baloto y visualizar frecuencias por número y posición, distribuciones y resúmenes temporales. El proyecto está en una etapa de prototipo: los datos se obtienen en tiempo de ejecución desde una página web de terceros y no se guardan en una base de datos local.

## Estado actual

El código implementa estas funciones:

- Obtiene una tabla HTML desde `resultadobaloto.com` y transforma fecha, combinación principal y Superbalota.
- Muestra los resultados cargados en una tabla interactiva.
- Calcula y grafica frecuencias globales por balota.
- Presenta distribuciones por posición mediante diagramas de caja, histogramas, tabla de frecuencias y mapa de calor.
- Calcula promedios acumulados y medias móviles con tamaño de ventana configurable.
- Permite descargar como CSV la tabla de frecuencias por posición.
- Muestra errores de adquisición y ofrece volver a intentar la carga.

La navegación también muestra apartados para correlaciones, pruebas estadísticas y aleatoriedad, pero sus componentes de análisis no están conectados en el servidor. Aunque se mencionan en el README anterior, no hay una base de datos histórica local, simulación de sorteos ni capacidad predictiva implementadas.

## Requisitos

- R 4.x.
- Conexión a Internet para obtener la tabla de resultados.
- Paquetes de R: `shiny`, `shinydashboard`, `DT`, `plotly`, `shinyjs`, `rvest` y `tidyverse`.

Instala las dependencias desde R:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "DT",
  "plotly",
  "shinyjs",
  "rvest",
  "tidyverse"
))
```

## Ejecución

Desde la raíz del repositorio:

```bash
cd project-test
R -e "shiny::runApp('.', port = 3536)"
```

Desde RStudio, establece `project-test` como directorio de trabajo y ejecuta `shiny::runApp()`.

## Fuente y flujo de datos

La función `obtener_datos_reales()` descarga y analiza una página HTML concreta de `resultadobaloto.com/resultados.php`. La implementación selecciona la segunda tabla encontrada y espera encabezados específicos. Por ello, el resultado depende de la disponibilidad del sitio y de que su estructura HTML no cambie.

Los datos se cargan al iniciar la sesión de Shiny y se vuelven a solicitar con **Actualizar Datos**. La interfaz muestra la fecha de consulta, no necesariamente la fecha del último sorteo incluido. No hay caché, snapshot versionado ni mecanismo de auditoría de los datos descargados.

## Análisis disponible

- **Distribuciones:** frecuencias por balota y diagramas de caja por posición.
- **Tendencias:** media acumulada o media móvil por balota; la ventana móvil se configura desde la interfaz.
- **Por posición:** mapa de calor, histograma comparativo, tabla de contingencia y descarga CSV.

Estas vistas son descriptivas. Una frecuencia o tendencia aparente no demuestra que un número tenga más probabilidad de salir en sorteos futuros.

## Estructura

```text
project-test/
├── global.R   # Adquisición, transformación y funciones de análisis/gráficos
├── ui.R       # Interfaz y navegación Shiny
├── server.R   # Carga reactiva y conexión de cálculos con la interfaz
└── Readme.md  # Documentación del proyecto
```

## Límites conocidos

- El scraping depende de un sitio de terceros y de la posición fija de una tabla HTML; un cambio del sitio puede interrumpir la carga o alterar los datos sin una validación suficiente.
- No se valida de forma completa la estructura, unicidad, rangos ni continuidad de los sorteos después de la extracción.
- Los datos descargados no quedan guardados. No es posible reproducir directamente un análisis anterior si la fuente cambia.
- Los apartados de correlaciones, pruebas de uniformidad y aleatoriedad tienen elementos de interfaz, pero no salidas de servidor funcionales.
- El botón **Actualizar Análisis** solo muestra una notificación; los cálculos reactivos ya se actualizan al cambiar sus dependencias.
- Algunos textos de la interfaz afirman que hay filtros o una fuente oficial que no corresponden al flujo de datos implementado: la fuente del scraper es un sitio de terceros y no se ven controles de filtro por fecha conectados.
- La función de frecuencias analiza las columnas numéricas devueltas por el scraper. Hay que comprobar explícitamente que el tratamiento de Superbalota y los espacios de números posibles sea correcto antes de interpretar comparaciones entre balotas.
- No hay pruebas automatizadas ni fixtures versionados para comprobar el parsing y los cálculos.

## Perspectivas de desarrollo

1. **Hacer robusta la adquisición:** comprobar la respuesta HTTP, seleccionar tablas por contenido y validar encabezados, tipos, rangos, duplicados y fechas antes de aceptar resultados. Añadir mensajes claros ante cambios de la fuente.
2. **Conservar procedencia:** guardar snapshots fechados de los datos crudos y normalizados, registrar fuente y fecha de consulta, y poder repetir los análisis sobre un conjunto identificado.
3. **Definir el modelo de datos:** separar las cinco balotas principales de la Superbalota, representar cada sorteo con un identificador y documentar las reglas y rangos vigentes para cada periodo. No asumir que el reglamento fue constante a lo largo de todo el histórico.
4. **Completar las pruebas estadísticas:** implementar pruebas apropiadas para el diseño y los rangos de cada posición, explicar supuestos y tamaño muestral, controlar comparaciones múltiples cuando aplique e incluir simulaciones bajo una hipótesis nula como referencia.
5. **Alinear la interfaz con el servidor:** conectar los apartados de correlación y validación solo cuando sus análisis existan; de lo contrario, marcarlos como pendientes o retirarlos temporalmente. Corregir textos de filtros y fuente para que describan el comportamiento real.
6. **Añadir pruebas y documentación de resultados:** crear datos de prueba pequeños, comprobar funciones de parsing y análisis, y documentar cómo reproducir cada estadístico y gráfico.

La prioridad recomendada es asegurar la integridad y reproducibilidad de los datos históricos. Después conviene completar las pruebas estadísticas. No se recomienda desarrollar “predicciones” o números calientes/fríos como estrategia de apuesta: en un sorteo aleatorio, patrones descriptivos pasados no garantizan una ventaja futura.

## Uso responsable

La aplicación es una herramienta educativa y descriptiva, no una guía para apostar. Los sorteos son aleatorios; los análisis históricos no permiten conocer ni garantizar resultados futuros. Verifica siempre las reglas vigentes con fuentes oficiales y respeta las condiciones de uso de la fuente consultada.
