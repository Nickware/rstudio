# Running Dashboard

Aplicación Shiny diseñada para visualizar, analizar y comparar datos de actividades de running, con énfasis en la información cardiovascular y de rendimiento.

## Descripción

Esta aplicación permite cargar archivos CSV con datos de actividades de running y visualizar información clave en un dashboard interactivo. Incluye análisis general, detalles de cada carrera, información cardiovascular y una herramienta para comparar dos actividades.

## Características principales

- **Carga de archivos:** Carga archivos CSV con datos de running.
- **Visualización general:** Muestra un histograma de actividades y resúmenes numéricos (número total de actividades, distancia total, tiempo total, ritmo medio, cadencia media y longitud media de zancada).
- **Detalle de actividad:** Permite seleccionar una fecha y ver detalles específicos de una carrera (distancia, tiempo, ritmo medio, cadencia, longitud de zancada, calorías, frecuencia cardíaca, efecto de entrenamiento aeróbico).
- **Información cardiovascular:** Visualiza gráficos relacionados con la temperatura y la altura (o cualquier otra métrica relevante según los datos cargados).
- **Comparación de actividades:** Compara dos actividades seleccionadas, mostrando los datos en tablas y un gráfico comparativo.


## Requisitos

- **R** (versión recomendada: 4.x o superior)
- **RStudio** (opcional, pero recomendado para desarrollo)
- **Paquetes de R:**
    - `shiny`
    - `shinydashboard`
    - `plotly`


## Instalación

1. **Instala los paquetes necesarios:**

```r
install.packages(c("shiny", "shinydashboard", "plotly"))
```

2. **Descargar o clonar el repositorio.**
3. **Abre el archivo `app.R` en RStudio (o ejecútalo desde la consola de R).**

```r
shiny::runApp()
```


## Uso

1. **Carga archivo CSV:**
It a la pestaña "Data File" y seleccionar archivo CSV.
2. **Explora la información general:**
Consultar el histograma y los resúmenes en la pestaña "Informacion General".
3. **Consulta detalles de una actividad:**
Seleccionar una fecha en la pestaña "Run Info" para ver detalles específicos.
4. **Visualiza información cardiovascular:**
Hacer click en la pestaña "Cardio Info" para ver gráficos relacionados.
5. **Compara actividades:**
En la pestaña "Comparar actividades", selecciona dos fechas para comparar sus datos.

## Estructura del código

El dashboard está estructurado en las siguientes pestañas:

- **Data File:** Carga y visualización de archivos CSV.
- **Informacion General:** Resumen estadístico y gráfico de actividades.
- **Run Info:** Detalles de cada carrera.
- **Cardio Info:** Información cardiovascular.
- **Comparar actividades:** Comparación de dos actividades.


## Ejemplo de datos

Asegúrarse que el archivo CSV contenga al menos las siguientes columnas (o similares):

- `Fecha`
- `Distancia`
- `Tiempo`
- `Ritmo.medio`
- `Cadencia.de.carrera.media`
- `Longitud.media.de.zancada`
- `Calorias`
- `Frecuencia.cardiaca.media`
- `TE.aeróbico`
