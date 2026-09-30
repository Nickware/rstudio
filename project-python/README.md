# Proyecto Python

## Estado actual

Esta carpeta está reservada para un futuro componente en Python, pero actualmente no contiene código, dependencias, pruebas ni datos. Por tanto, todavía no existe una aplicación Python ejecutable ni una integración con los proyectos de R/Shiny del repositorio.

Las ideas de este documento son propuestas, no funcionalidades ya disponibles. Los proyectos de referencia son [`project-biomechanics`](../project-biomechanics/), [`project-runner`](../project-runner/) y el analizador de Baloto en [`project-test`](../project-test/).

## Enfoque de colaboración

Una separación práctica sería usar Python para tareas reutilizables de ingesta, validación, procesamiento por lotes y pruebas; R/Shiny puede seguir siendo la capa de exploración interactiva y presentación donde ya existen dashboards. Los resultados podrían intercambiarse primero como CSV o Parquet con un esquema documentado. `reticulate` o una API solo tendrían sentido si más adelante se necesita ejecutar Python directamente desde R o servir varios consumidores.

No conviene duplicar en ambos lenguajes las mismas transformaciones sin definir una fuente de verdad para nombres de columnas, unidades, fechas, identificadores y datos faltantes.

## Líneas de proyecto

### Biomecánica del running

[`project-biomechanics`](../project-biomechanics/) importa CSV Garmin individuales y colectivos, normaliza métricas y permite revisar datos en Shiny. Su análisis longitudinal todavía es una perspectiva. Un complemento Python podría:

- validar los archivos contra esquemas explícitos y producir un informe de errores por archivo;
- estandarizar tipos, unidades, fechas, semanas de entrenamiento e identificadores de actividad;
- generar un conjunto procesado y trazable para que R/Shiny explore cambios por sujeto, semana y superficie;
- más adelante, comparar métodos de extracción de señales o modelos longitudinales con pruebas y diagnósticos reproducibles.

La hipótesis de una transición desde un comportamiento más oscilatorio a uno más estable debe tratarse como pregunta científica. Primero hacen falta observaciones longitudinales consistentes y una definición medible de estabilidad; un modelo no debe presentarse como confirmación automática.

### Baloto Analyzer

[`project-test`](../project-test/) contiene el analizador Shiny de Baloto: obtiene resultados históricos desde una web y calcula frecuencias, estadísticas por posición, visualizaciones y series temporales. La interfaz también anuncia pruebas y análisis que no están todos conectados. Python podría complementar el proyecto mediante:

- una ingesta histórica verificable, con validación de fechas, reglas del sorteo, duplicados y cambios de formato;
- pruebas estadísticas reproducibles de uniformidad e independencia, con simulaciones bajo hipótesis nulas y explicación de sus límites;
- comparación automática entre resultados observados y simulados, exportando tablas que Shiny pueda visualizar;
- pruebas de regresión para detectar cambios en la fuente de datos o en el cálculo de estadísticas.

Los sorteos están diseñados para ser aleatorios. Frecuencias históricas o modelos predictivos no permiten garantizar ni inferir una combinación ganadora; cualquier simulación debe presentarse como exploración estadística o entretenimiento, no como estrategia para mejorar las probabilidades.

### Running Dashboard

[`project-runner`](../project-runner/) ya ofrece un dashboard Shiny para cargar resúmenes CSV de Garmin y archivos FIT con telemetría, y explorar sesiones, evolución, comparaciones, fisiología y biomecánica. Un componente Python podría:

- evaluar parsers FIT mantenidos y contrastarlos con el parser actual mediante archivos de prueba conocidos;
- ejecutar validaciones de calidad de telemetría, detectar huecos o valores fuera de rango y resumirlos por sesión;
- extraer características por vuelta o ventanas de tiempo y guardarlas en un formato común para el dashboard;
- explorar anonimización de coordenadas GPS antes de compartir datos de ejemplo o resultados.

La integración inicial más sencilla sería un comando o proceso Python que produzca archivos procesados con un esquema versionado, dejando la visualización y el flujo interactivo en R/Shiny. Antes de reemplazar lógica existente, habría que comparar resultados, unidades, casos límite y rendimiento.

## Perspectivas de desarrollo

1. **Elegir un primer problema:** priorizar una tarea acotada compartida por los proyectos de running, como validar y normalizar un CSV Garmin, o una necesidad analítica pendiente en Baloto.
2. **Definir contratos de datos:** documentar nombres, tipos, unidades, zonas horarias, identificadores, valores faltantes y versión del esquema. Mantener fixtures pequeños y anonimizados.
3. **Crear una base Python reproducible:** decidir entre una biblioteca/CLI y notebooks; fijar dependencias, añadir pruebas automatizadas y documentar instalación y ejecución.
4. **Conectar con R de forma simple:** comenzar con CSV o Parquet y salidas deterministas. Adoptar `reticulate` o una API solo cuando haya una necesidad concreta de intercambio en tiempo real o de múltiples consumidores.
5. **Validar los resultados:** comparar salidas Python y R en casos conocidos, registrar supuestos y advertir incertidumbre antes de incorporar nuevas métricas o modelos.

## Primer hito recomendado

Construir un validador Python de exportaciones Garmin que acepte una muestra anonimizada, identifique el formato, compruebe campos requeridos y unidades, y produzca un archivo normalizado más un reporte legible. El resultado se podría abrir en `project-biomechanics` o `project-runner` sin cambiar todavía sus aplicaciones. Este hito probaría la interoperabilidad y aportaría una utilidad concreta antes de decidir si se necesitan notebooks, `reticulate` o un servicio.

## Inicio

No hay instrucciones de ejecución todavía: el directorio sigue sin implementación ni entorno de dependencias. Añádanse cuando se acuerde y construya el primer hito.