# Running Dashboard

Aplicación en R y Shiny para revisar sesiones de running de Garmin. Combina archivos FIT con telemetría y archivos CSV de Garmin Connect con resúmenes por actividad. Permite explorar métricas por sesión, su evolución, comparaciones y gráficos de fisiología y biomecánica.

## Estado actual

La aplicación está implementada con la estructura clásica de Shiny: `ui.R` define seis pestañas y `server.R` contiene los parsers y cálculos reactivos.

- **Datos:** carga múltiple de archivos `.fit`, `.csv` o ambos; presenta resúmenes por sesión, indicadores globales y errores de carga.
- **Sesión:** muestra métricas de una actividad, curvas de frecuencia cardiaca y ritmo, cadencia y altitud, y detalles por vuelta cuando hay telemetría FIT.
- **Evolución:** grafica distancia, ritmo, cadencia, frecuencia cardiaca y una métrica de eficiencia aeróbica por fecha.
- **Comparar:** contrasta dos sesiones con métricas normalizadas y superpone la frecuencia cardiaca frente a la distancia cuando ambas tienen telemetría FIT.
- **Fisiología:** incluye zonas de frecuencia cardiaca, deriva cardiaca y carga semanal.
- **Biomecánica:** explora cadencia y longitud de zancada, cadencia frente a velocidad por zona de frecuencia cardiaca, variación de cadencia entre mitades y consistencia del ritmo por vuelta.

El resumen CSV aporta estadísticas por actividad, pero no telemetría segundo a segundo. Las vistas intrasesión y de superposición de telemetría requieren archivos FIT compatibles.

## Requisitos

- R 4.x.
- Paquetes de R: `shiny`, `shinydashboard`, `dplyr`, `tidyr`, `ggplot2`, `plotly` y `lubridate`.
- RStudio es opcional.

Instala las dependencias desde R:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "dplyr",
  "tidyr",
  "ggplot2",
  "plotly",
  "lubridate"
))
```

## Ejecución

Desde la raíz del repositorio:

```bash
cd project-runner
R -e "shiny::runApp('.', port = 3535)"
```

También puedes abrir `project-runner.Rproj` en RStudio y ejecutar la aplicación desde esa carpeta. Al iniciar, abre `http://127.0.0.1:3535`.

## Datos de entrada

### Archivos FIT

Selecciona uno o varios archivos `.fit` exportados por Garmin. El parser incluido extrae un subconjunto de datos de registros y vueltas: marcas de tiempo, posición GPS, altitud, frecuencia cardiaca, cadencia, distancia, velocidad, temperatura y algunas métricas de vuelta. La cobertura depende de los campos presentes en el archivo.

### Archivos CSV

Selecciona exportaciones CSV de Garmin Connect con una fila por actividad. El parser normaliza encabezados en español e inglés y busca campos como fecha, distancia, duración, ritmo, frecuencia cardiaca, cadencia, elevación, calorías, zancada y métricas de entrenamiento. La fecha válida es necesaria para conservar la fila; otros campos pueden quedar ausentes si no están en el archivo.

Es posible cargar ambos formatos en una misma sesión. Si hay un resumen CSV y un FIT para una actividad, comprueba que sus fechas y métricas correspondan antes de interpretar la combinación. No se incluyen archivos de datos de ejemplo en el proyecto.

## Estructura

```text
project-runner/
├── ui.R                    # Interfaz Shiny y pestañas del dashboard
├── server.R                # Parsers FIT/CSV, cálculos y salidas reactivas
└── project-runner.Rproj     # Proyecto de RStudio
```

## Límites conocidos

- El parser FIT es una implementación propia que reconoce un subconjunto de campos; no sustituye una validación completa del estándar FIT. En su estado actual omite los registros comprimidos, por lo que archivos que los usen pueden quedar incompletos.
- La telemetría y las vueltas se indexan por fecha. Dos actividades del mismo día pueden resultar ambiguas al seleccionar o recuperar sus registros.
- La normalización CSV depende de nombres alternativos conocidos y del formato de las fechas y métricas; archivos con otros encabezados pueden producir campos vacíos o ser rechazados.
- Algunas métricas y gráficas dependen de columnas opcionales; la ausencia de datos puede limitar lo que se muestra.
- No se observan pruebas automatizadas ni un conjunto de datos pequeño versionado para verificar parsers y cálculos.
- Los indicadores derivados, como eficiencia aeróbica, son exploratorios y dependen de unidades, calidad del sensor y contexto de cada sesión; no son diagnósticos clínicos.

## Perspectivas de desarrollo

1. **Proteger la lectura de datos:** crear archivos FIT/CSV anonimizados de prueba y verificar fechas, distancias, escalas, valores ausentes, vueltas y manejo de errores. Comparar el parser FIT actual con una biblioteca mantenida o con salidas de referencia conocidas.
2. **Corregir identidad de sesiones:** asignar un identificador estable, por ejemplo basado en fecha-hora y origen, y asociar resúmenes, telemetría y vueltas mediante ese identificador en vez de usar únicamente la fecha.
3. **Hacer explícita la calidad:** informar por archivo qué campos se detectaron, qué unidades se asumieron y qué métricas no están disponibles; distinguir valores faltantes de ceros reales.
4. **Mejorar comparaciones:** permitir filtrar por periodo, tipo de actividad o condiciones disponibles, y mostrar cantidad de sesiones, distribución y variabilidad además de promedios.
5. **Aumentar reproducibilidad:** exportar un conjunto normalizado y un resumen del procesamiento, incluyendo versión del esquema y archivos de origen; documentar cómo se calculan las métricas derivadas.
6. **Ampliar el análisis con cautela:** explorar tendencias longitudinales y biomecánicas solo con suficientes sesiones comparables, explicitando incertidumbre y evitando inferir causalidad a partir de gráficos descriptivos.

El orden recomendado es asegurar primero la exactitud del parser y la asociación de sesiones. De lo contrario, mejoras visuales o modelos adicionales podrían amplificar errores de entrada sin hacerlos evidentes.

## Licencia y uso

Este proyecto es una herramienta de exploración de datos deportivos. Verifica las condiciones de uso de las exportaciones de Garmin y protege la privacidad de las personas, especialmente si los FIT contienen coordenadas GPS. Las visualizaciones no sustituyen asesoramiento médico ni evaluación profesional.
