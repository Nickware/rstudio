# Análisis de biomecánica al correr

Aplicación en R y Shiny para importar y explorar datos de actividades de running exportados desde Garmin. El proyecto está en una etapa inicial: el flujo implementado se concentra en la carga, validación básica, normalización y vista previa de datos. El análisis longitudinal completo y el modelo biomecánico planteados como objetivo todavía no están implementados en la interfaz.

## Objetivo

El propósito de investigación es seguir la evolución de métricas de carrera y comparar sesiones realizadas en cinta y asfalto. Una hipótesis posible es que ciertos indicadores cambien con el entrenamiento desde un patrón más variable u oscilatorio hacia uno más estable. Esto es una pregunta por evaluar con datos adecuados; la aplicación actual no prueba ni confirma esa hipótesis.

## Estado actual

La aplicación permite:

- Cargar un CSV de actividad individual.
- Cargar varios CSV individuales y seleccionar cuáles procesar.
- Cargar un CSV colectivo con resúmenes de actividades.
- Revisar una muestra del archivo e información básica de su estructura.
- Validar un conjunto mínimo de encabezados antes del procesamiento.
- Normalizar métricas a nombres comunes y añadir metadatos de sujeto y superficie.
- Consultar una tabla de datos normalizados, histogramas de métricas disponibles y un resumen de carga.

La información procesada se mantiene en memoria durante la sesión. Actualmente no hay persistencia en disco, exportación desde la interfaz ni un módulo de análisis longitudinal conectado.

## Requisitos

- R 4.x.
- Paquetes de R: `shiny`, `shinydashboard`, `shinyjs`, `tidyverse` y `DT`.
- RStudio es opcional; la aplicación también se puede iniciar desde una terminal.

Para configurar un entorno Linux aislado con Distrobox, consulta la [guía de instalación del contenedor](docs/instalacion-contenedor.md).

## Ejecución

Desde RStudio, abre `app.R` y selecciona **Run App**. Desde una terminal, ejecuta:

```bash
cd project-biomechanics
R -e "shiny::runApp('.', port = 3535)"
```

Después abre `http://127.0.0.1:3535` en el navegador. El proceso carga los módulos y archivos relativos al directorio del proyecto; por eso conviene iniciar la aplicación desde esta carpeta.

## Flujo de carga

1. Elige uno de los modos: actividad individual, múltiples actividades individuales o archivo colectivo.
2. Selecciona el CSV exportado desde Garmin.
3. Revisa la vista previa y el diagnóstico de estructura.
4. Indica el sujeto y la superficie para el lote que vas a procesar.
5. Pulsa **Procesar y Normalizar** y consulta la pestaña de datos normalizados o las estadísticas.

Los nombres de columna esperados corresponden a los encabezados reconocidos por los esquemas del proyecto, definidos en [`R/schemas.R`](R/schemas.R). Para una actividad individual, la validación mínima revisa `Vueltas`, `Tiempo`, `Distancia`, `Ritmo.medio`, `Frecuencia.cardiaca.media` y `Cadencia.de.carrera.media`. Para archivos colectivos se buscan encabezados de actividad, fecha, distancia, tiempo, frecuencia cardiaca y cadencia; el validador actual exige al menos cuatro coincidencias y 30 filas.

Estos controles son una validación básica, no una garantía de compatibilidad completa: la normalización también referencia otras columnas del formato Garmin. Un archivo puede pasar la comprobación mínima y aun así fallar si carece de campos usados durante el procesamiento. La limpieza actual excluye filas cuyo campo `Vueltas` contiene “Resumen” en los modos individuales.

## Métricas normalizadas

Según el formato y las columnas disponibles, se renombran métricas como distancia, ritmo, frecuencia cardiaca, cadencia, tiempo de contacto con el suelo, longitud de zancada, oscilación vertical, potencia, ascenso, descenso, calorías y temperatura. También se agregan `actividad_id`, `tipo_dato`, `sujeto` y `superficie`.

Hay diferencias entre los formatos: las actividades individuales conservan métricas por vuelta y no obtienen una fecha o semana; el formato colectivo incluye fecha y valores resumidos por actividad. Los CSV cargados no se guardan automáticamente y los metadatos elegidos se aplican al lote procesado.

## Estructura del proyecto

```text
project-biomechanics/
├── app.R                         # Aplicación Shiny y navegación principal
├── docs/
│   └── instalacion-contenedor.md  # Entorno aislado con Distrobox
├── modules/
│   ├── data_import_ui.R           # Interfaz de importación y vistas
│   └── data_import_server.R       # Validación, normalización y estadísticas
└── R/
        ├── schemas.R                  # Mapeo de encabezados Garmin
        └── detector_tipo.R            # Validación y normalización de datos
```

## Límites conocidos

- El menú muestra **Análisis Temporal** y **Modelo Oscilador**, pero la interfaz solo registra la pestaña de ingesta; esos apartados aún no tienen vistas implementadas.
- El gráfico de evolución temporal necesita una semana válida, pero el normalizador asigna `semana = NA`. Por ello no debe interpretarse como un análisis longitudinal funcional.
- La detección automática de formato está definida en el código, aunque el flujo de carga actual valida el modo que el usuario selecciona y no la utiliza para decidirlo automáticamente.
- La validación comprueba menos campos de los que la normalización puede necesitar; conviene endurecerla para producir errores claros antes del procesamiento.
- No hay pruebas automatizadas, almacenamiento de datos ni exportación de resultados en la estructura actual.

## Perspectivas de desarrollo

Una secuencia razonable para evolucionar el proyecto sería:

1. **Asegurar la ingesta:** alinear esquemas, validación y normalización; manejar columnas opcionales y tipos de datos; mostrar por archivo los campos faltantes y las filas descartadas. Añadir pruebas pequeñas con CSV anonimizados para cada formato.
2. **Conservar procedencia:** asignar fechas y semanas de forma consistente, identificar cada sesión sin depender del nombre de archivo y guardar los datos procesados junto con sujeto, superficie y versión del esquema. Incluir exportación para que el trabajo de una sesión no se pierda al cerrar la app.
3. **Construir el análisis longitudinal:** primero describir cobertura y calidad de los datos; después comparar métricas por sujeto, semana y superficie, mostrando cantidad de sesiones y datos faltantes. Evitar inferencias si el diseño o el tamaño muestral no las respaldan.
4. **Evaluar la hipótesis dinámica:** definir operacionalmente qué significa “estabilidad” y qué observaciones permitirían distinguirla de variación normal. Solo entonces comparar modelos longitudinales sencillos; considerar un oscilador amortiguado si la resolución temporal, el número de observaciones y el ajuste del modelo lo justifican.
5. **Completar la interfaz científica:** conectar las vistas temporal y de modelo a resultados reproducibles, incorporar incertidumbre y diagnósticos, y generar un informe con datos, filtros, supuestos y límites del análisis.

La prioridad es asegurar datos comparables y trazables antes de añadir modelos complejos. El planteamiento del oscilador puede ser una perspectiva interesante, pero primero requiere una definición medible de estabilidad y suficiente evidencia longitudinal.

## Licencia y uso

El proyecto está orientado a fines académicos y de exploración científica. Los resultados dependen de la calidad de los datos y del diseño del estudio; no constituyen por sí solos una evaluación clínica ni una recomendación de entrenamiento. La interpretación final debe considerar el contexto y las limitaciones del estudio.

La distribución del código y de los datos debe respetar las licencias y condiciones de uso aplicables.
Los datos de Garmin deben tratarse según las condiciones de uso del servicio y la privacidad de las personas participantes.

