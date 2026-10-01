# Proyecto Python

## Estado actual

Esta carpeta está reservada para un futuro componente en Python, pero actualmente no contiene código, dependencias, pruebas ni datos. Por tanto, todavía no existe una aplicación Python ejecutable ni una integración con los proyectos de R/Shiny del repositorio.

El repositorio incluye aplicaciones relacionadas con actividades de running y biomecánica en [`project-runner`](../project-runner/) y [`project-biomechanics`](../project-biomechanics/). La posible relación con este directorio es una dirección de trabajo, no una integración existente.

## Propósito posible

Una función útil para este proyecto sería complementar las aplicaciones de R con herramientas reproducibles de procesamiento o análisis de datos de running. Por ejemplo, Python podría servir para:

- Validar y transformar exportaciones de actividades a un formato tabular documentado.
- Ejecutar análisis exploratorios o comparaciones que se quieran mantener en Python.
- Probar con datos anonimizados que las transformaciones producen resultados consistentes.
- Compartir conjuntos procesados con las aplicaciones R mediante formatos abiertos como CSV o Parquet.

Antes de implementar estas ideas conviene acordar qué problema concreto resolverá el componente Python y qué responsabilidad conservarán las aplicaciones existentes. Evitar duplicar la normalización en dos lenguajes sin una definición común de columnas, unidades, fechas e identificadores de actividad.

## Perspectivas de desarrollo

1. **Definir el alcance:** decidir si será una biblioteca de procesamiento, scripts de análisis, notebooks o una aplicación independiente. Elegir una primera tarea pequeña y verificable.
2. **Acordar el contrato de datos:** documentar nombres de campos, tipos, unidades, valores ausentes e identificadores. Comparar ese contrato con los esquemas Garmin de `project-biomechanics` y los formatos leídos por `project-runner`.
3. **Crear una base reproducible:** incorporar un entorno de dependencias fijadas, instrucciones de instalación, configuración de linting y pruebas automatizadas. Mantener las muestras de prueba anonimizadas y pequeñas.
4. **Implementar un flujo vertical mínimo:** leer un archivo de ejemplo, validar su estructura, producir una salida documentada y comprobarla con una prueba. Mantener la integración con las apps R mediante archivos explícitos mientras no exista una necesidad clara de una API compartida.
5. **Evaluar el análisis científico:** añadir modelos o procesamiento de señales solo cuando haya una pregunta concreta, datos suficientes y criterios para validar los resultados; reportar supuestos e incertidumbre.

La prioridad recomendada es acordar el formato de intercambio con los proyectos existentes. Esto permitiría que Python aporte capacidades propias sin crear dos versiones incompatibles del mismo procesamiento.

## Inicio

No hay instrucciones de ejecución todavía, porque aún no se ha añadido una implementación ni se han elegido sus herramientas. Esta sección deberá actualizarse cuando se defina el alcance y se establezca el primer flujo funcional.