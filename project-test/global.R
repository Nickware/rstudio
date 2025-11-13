library(rvest)
library(tidyverse)
library(plotly)

# Función principal de scraping
obtener_datos_reales <- function() {
  tryCatch({
    url <- "https://www.resultadobaloto.com/resultados.php"
    tabla <- read_html(url) %>% 
      html_nodes("table") %>% 
      .[[2]] %>% 
      html_table()
    
    tabla %>%
      rename(
        Fecha = 1,
        Combinacion = "Combinación Ganadora",
        SuperBalota = "Super Balota."
      ) %>%
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

# Cálculo de frecuencias globales
calcular_frecuencias <- function(datos) {
  datos %>%
    select(-Fecha) %>%
    pivot_longer(
      cols = everything(),
      names_to = "Balota",
      values_to = "Numero"
    ) %>%
    count(Balota, Numero, name = "Frecuencia")
}

# Función para análisis por posición
calcular_estadisticas_posicion <- function(datos) {
  datos %>%
    select(-Fecha) %>%
    pivot_longer(
      everything(),
      names_to = "Posicion",
      values_to = "Numero"
    ) %>%
    group_by(Posicion, Numero) %>%
    summarise(
      Frecuencia = n(),
      .groups = "drop_last"
    ) %>%
    mutate(
      Frecuencia_Relativa = Frecuencia / sum(Frecuencia)
    ) %>%
    arrange(Posicion, desc(Frecuencia))
}

# Función para heatmap de posición
generar_heatmap_posicion <- function(datos_estadisticas) {
  datos_estadisticas %>%
    plot_ly(
      x = ~Numero,
      y = ~Posicion,
      z = ~Frecuencia,
      type = "heatmap",
      colors = colorRamp(c("#FFFFFF", "#1E88E5")),
      hoverinfo = "text",
      text = ~paste(
        "<b>Posición:</b>", Posicion,
        "<br><b>Número:</b>", Numero,
        "<br><b>Frecuencia:</b>", Frecuencia,
        "<br><b>Frec. Relativa:</b>", round(Frecuencia_Relativa * 100, 1), "%"
      )
    ) %>%
    layout(
      xaxis = list(title = "Número"),
      yaxis = list(title = "Posición"),
      margin = list(l = 100)
    )
}

# Función para preparar datos de boxplot
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
  datos_boxplot %>%
    plot_ly(
      x = ~Posicion,
      y = ~Numero,
      color = ~Posicion,
      type = "box",
      boxpoints = "all",
      jitter = 0.3,
      pointpos = -1.8,
      hoverinfo = "y",
      marker = list(
        size = 4,
        opacity = 0.7
      ),
      line = list(width = 2)
    ) %>%
    layout(
      title = "Distribución de Números por Posición",
      xaxis = list(title = "Posición en el Sorteo"),
      yaxis = list(title = "Valor del Número"),
      showlegend = FALSE,
      margin = list(l = 50, r = 50, b = 50, t = 50)
    )
}

# Función para series temporales (promedios acumulados)
preparar_series_temporales <- function(datos) {
  datos %>%
    arrange(Fecha) %>%
    mutate(
      # Calcular promedio acumulado para cada balota
      across(starts_with("Balota") | contains("SuperBalota"), 
             ~ cummean(.), 
             .names = "Promedio_{.col}")
    ) %>%
    select(Fecha, starts_with("Promedio_")) %>%
    pivot_longer(
      cols = -Fecha,
      names_to = "Balota",
      values_to = "Promedio_Acumulado"
    ) %>%
    mutate(
      Balota = str_remove(Balota, "Promedio_"),
      Balota = factor(Balota,
                     levels = c(paste0("Balota0", 1:5), "SuperBalota"),
                     labels = c("Balota 1", "Balota 2", "Balota 3", 
                               "Balota 4", "Balota 5", "SuperBalota"))
    )
}

# Función para medias móviles (sin zoo)
preparar_medias_moviles <- function(datos, ventana = 20) {
  # Función para calcular media móvil manualmente
  calcular_media_movil <- function(x, n) {
    stats::filter(x, rep(1/n, n), sides = 1)
  }
  
  datos %>%
    arrange(Fecha) %>%
    mutate(
      across(starts_with("Balota") | contains("SuperBalota"), 
             ~ calcular_media_movil(., ventana),
             .names = "MM_{.col}")
    ) %>%
    select(Fecha, starts_with("MM_")) %>%
    pivot_longer(
      cols = -Fecha,
      names_to = "Balota",
      values_to = "Media_Movil"
    ) %>%
    mutate(
      Balota = str_remove(Balota, "MM_"),
      Balota = factor(Balota,
                     levels = c(paste0("Balota0", 1:5), "SuperBalota"),
                     labels = c("Balota 1", "Balota 2", "Balota 3", 
                               "Balota 4", "Balota 5", "SuperBalota"))
    ) %>%
    filter(!is.na(Media_Movil))
}

# Función para generar gráfico de series temporales
generar_grafico_series <- function(datos_series, tipo = "acumuladas") {
  if (tipo == "acumuladas") {
    plot_ly(datos_series) %>%
      add_trace(
        x = ~Fecha,
        y = ~Promedio_Acumulado,
        color = ~Balota,
        type = "scatter",
        mode = "lines",
        line = list(width = 2),
        hoverinfo = "text",
        text = ~paste(
          "<b>Fecha:</b>", format(Fecha, "%d/%m/%Y"),
          "<br><b>Balota:</b>", Balota,
          "<br><b>Promedio Acumulado:</b>", round(Promedio_Acumulado, 1)
        )
      ) %>%
      layout(
        title = "Promedio Acumulado por Balota",
        xaxis = list(title = "Fecha"),
        yaxis = list(title = "Valor Promedio"),
        hovermode = "x unified"
      )
  } else {
    plot_ly(datos_series) %>%
      add_trace(
        x = ~Fecha,
        y = ~Media_Movil,
        color = ~Balota,
        type = "scatter",
        mode = "lines",
        line = list(width = 2),
        hoverinfo = "text",
        text = ~paste(
          "<b>Fecha:</b>", format(Fecha, "%d/%m/%Y"),
          "<br><b>Balota:</b>", Balota,
          "<br><b>Media Móvil:</b>", round(Media_Movil, 1)
        )
      ) %>%
      layout(
        title = "Medias Móviles por Balota",
        xaxis = list(title = "Fecha"),
        yaxis = list(title = "Valor Promedio"),
        hovermode = "x unified"
      )
  }
}