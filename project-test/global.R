library(rvest)
library(tidyverse)
library(ggplot2)

obtener_datos_reales <- function() {
  tryCatch({
    url <- "https://www.resultadobaloto.com/resultados.php"
    tabla <- read_html(url) %>%
      html_nodes("table") %>%
      .[[2]] %>%
      html_table()
    
    tabla %>%
      rename(Fecha = 1,
             Combinacion = "Combinación Ganadora",
             SuperBalota = "Super Balota.") %>%
      mutate(
        Fecha = as.Date(Fecha, format = "%d/%m/%Y"),
        Combinacion = gsub(" ", "", Combinacion)
      ) %>%
      separate(
        Combinacion,
        
        into = paste0("Balota0", 1:5),
        sep = "\\|",
        convert = TRUE
      )
  }, error = function(e) {
    stop(paste("Error en scraping:", e$message))
  })
}

calcular_frecuencias <- function(datos) {
  datos %>%
    select(-Fecha) %>%
    pivot_longer(everything(), names_to = "Balota", values_to = "Numero") %>%
    count(Balota, Numero, name = "Frecuencia")
}

# Función para gráficos interactivos
generar_grafico_interactivo <- function(frecuencias, balota_seleccionada) {
  datos_grafico <- frecuencias %>%
    filter(Balota == balota_seleccionada)
  
  # Paleta de colores por balota
  colores <- c("#1f77b4",
               "#ff7f0e",
               "#2ca02c",
               "#d62728",
               "#9467bd",
               "#8c564b")
  names(colores) <- c(paste0("Balota0", 1:5), "SuperBalota")
  
  plot_ly(
    data = datos_grafico,
    x = ~ as.factor(Numero),
    y = ~ Frecuencia,
    type = "bar",
    color = I(colores[balota_seleccionada]),
    hoverinfo = "text",
    text = ~ paste("Número:", Numero, "<br>Frecuencia:", Frecuencia),
    marker = list(line = list(color = "rgb(8,48,107)", width = 1.5))
  ) %>%
    layout(
      title = paste("Frecuencias -", balota_seleccionada),
      xaxis = list(title = "Número"),
      yaxis = list(title = "Frecuencia"),
      hoverlabel = list(bgcolor = "white")
    )
}

# Nueva función para análisis por posición
calcular_estadisticas_posicion <- function(datos) {
  datos %>%
    select(-Fecha) %>%
    pivot_longer(everything(), names_to = "Posicion", values_to = "Numero") %>%
    group_by(Posicion, Numero) %>%
    summarise(Frecuencia = n(), .groups = "drop_last") %>%
    mutate(Frecuencia_Relativa = Frecuencia / sum(Frecuencia)) %>%
    arrange(Posicion, desc(Frecuencia))
}

# Función para heatmap
generar_heatmap_posicion <- function(datos_estadisticas) {
  datos_estadisticas %>%
    plot_ly(
      x = ~ Numero,
      y = ~ Posicion,
      z = ~ Frecuencia,
      type = "heatmap",
      colors = colorRamp(c("#FFFFFF", "#1E88E5")),
      hoverinfo = "text",
      text = ~ paste(
        "<b>Posición:</b>",
        Posicion,
        "<br><b>Número:</b>",
        Numero,
        "<br><b>Frecuencia:</b>",
        Frecuencia,
        "<br><b>Frec. Relativa:</b>",
        round(Frecuencia_Relativa * 100, 1),
        "%"
      )
    ) %>%
    layout(
      xaxis = list(title = "Número"),
      yaxis = list(title = "Posición"),
      margin = list(l = 100)
    )
}


# Función para preparar datos para boxplots (Funcion)
preparar_datos_boxplot <- function(datos) {
  datos %>%
    select(-Fecha) %>%
    pivot_longer(
      cols = everything(),
      names_to = "Posicion",
      values_to = "Numero"
    ) %>%
    mutate(
      Posicion = factor(Posicion, 
                        levels = c(paste0("Balota0", 1:5), "SuperBalota"),
                        labels = c("Balota 1", "Balota 2", "Balota 3", 
                                   "Balota 4", "Balota 5", "SuperBalota"))
    )
}

# Función para generar boxplot
generar_boxplot_posiciones <- function(datos_boxplot) {
  # Paleta de colores personalizada
  colores <- c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b")
  
  datos_boxplot %>%
    plot_ly() %>%
    add_trace(
      x = ~Posicion,
      y = ~Numero,
      color = ~Posicion,
      colors = colores,
      type = "box",
      boxpoints = "suspectedoutliers",  # Solo muestra outliers sospechosos
      marker = list(
        color = "rgb(8,48,107)",
        outliercolor = "rgba(219, 64, 82, 0.6)",
        line = list(outliercolor = "rgba(219, 64, 82, 0.6)", 
                    outlierwidth = 2)
      ),
      line = list(color = "rgb(8,48,107)")
    ) %>%
    layout(
      title = list(text = "<b>Distribución por Posición</b>", x = 0.5),
      xaxis = list(title = "Posición en el Sorteo"),
      yaxis = list(title = "Valor del Número"),
      showlegend = FALSE,
      hovermode = "compare"
    )
}