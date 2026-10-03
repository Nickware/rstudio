# Proyectos de análisis con R y Shiny

Este repositorio reúne aplicaciones y prototipos independientes para explorar datos de running, biomecánica y resultados de Baloto, además de un espacio reservado para futuras herramientas en Python y scripts de instalación de RStudio para Linux. No es una única aplicación integrada; cada carpeta de proyecto tiene su propio código, requisitos e instrucciones.

## Proyectos

| Carpeta | Propósito | Estado / punto de entrada |
|---|---|---|
| [`project-biomechanics`](project-biomechanics/Readme.md) | Importar y normalizar exportaciones Garmin para explorar métricas de running y biomecánica. | App Shiny en etapa inicial, centrada en ingesta. La guía incluye límites y perspectivas longitudinales. |
| [`project-runner`](project-runner/Readme.md) | Dashboard para consultar y comparar sesiones Garmin a partir de FIT y CSV. | App Shiny con vistas de sesión, evolución, comparación, fisiología y biomecánica. |
| [`project-test`](project-test/Readme.md) | Baloto Analyzer: exploración descriptiva de resultados históricos por número y posición. | Prototipo Shiny dependiente de una fuente web de terceros; pruebas estadísticas de la interfaz aún pendientes de conexión. |
| [`project-python`](project-python/README.md) | Espacio propuesto para procesamiento, validación o análisis complementario en Python. | Actualmente no contiene implementación. El README perfila posibles colaboraciones con los proyectos R. |
| [`rstudio-install`](rstudio-install/README.md) | Guías y scripts para instalar R y RStudio en distribuciones Linux. | Incluye rutas distintas para Debian/Ubuntu y Fedora; revisa sus efectos antes de ejecutarlos. |

## Cómo empezar

1. Elige el proyecto que corresponda a tu tarea y lee su README antes de instalar dependencias o cargar datos.
2. Sigue las instrucciones de ejecución desde la carpeta del proyecto; las aplicaciones no comparten un comando de inicio común.
3. Revisa los formatos de entrada y las limitaciones documentadas. En particular, los archivos Garmin pueden incluir coordenadas GPS y deben tratarse con cuidado.

Los README individuales documentan requisitos e instalación específicos. Los proyectos R usan R y Shiny; RStudio Desktop es opcional para ejecutarlos desde una terminal. Para instalar RStudio en Linux, consulta [`rstudio-install`](rstudio-install/README.md).

## Relación entre proyectos

`project-runner` y `project-biomechanics` se ocupan de datos de running, pero son aplicaciones independientes con flujos de carga y análisis distintos. `project-python` plantea posibles utilidades compartidas, todavía no implementadas; un primer paso razonable sería acordar un formato de datos común antes de integrar procesos entre lenguajes.

Baloto Analyzer es un proyecto separado. Sus gráficos y estadísticas actuales son descriptivos: no permiten predecir ni garantizar resultados futuros de un sorteo aleatorio.

## Tecnologías

- R y Shiny para las aplicaciones interactivas.
- `shinydashboard`, `plotly` y `DT` en distintos proyectos para navegación y visualización.
- Python está contemplado como posible complemento, pero aún no hay código Python en el repositorio.
- Git para versionar los proyectos y su documentación.

## Datos, reproducibilidad y uso

No asumas que las aplicaciones comparten datos o resultados. Verifica la procedencia, unidades, fechas y campos disponibles en cada flujo. Algunas funciones dependen de exportaciones de Garmin o de páginas externas y pueden cambiar si sus formatos o estructuras cambian. Consulta el README específico para conocer esos límites.

Anonimiza los datos antes de compartirlos, especialmente si contienen rutas GPS o información identificable. Los análisis de running son exploratorios y no sustituyen evaluaciones médicas; el analizador de Baloto no es una estrategia de apuestas. Respeta las condiciones de uso de las fuentes y los datos utilizados.

## Agente para el repositorio

Para crear y probar en VS Code un agente mantenedor con permisos graduales, sigue la [guía paso a paso](docs/repo-agent/README.md).



