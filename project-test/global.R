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

calcular_frecuencias <- function(datos) {
  datos %>%
    select(-Fecha) %>%
    pivot_longer(
      everything(),
      names_to = "Balota",
      values_to = "Numero"
    ) %>%
    count(Balota, Numero, name = "Frecuencia")
}

# Función para gráficos interactivos
generar_grafico_interactivo <- function(frecuencias, balota_seleccionada) {
  datos_grafico <- frecuencias %>%
    filter(Balota == balota_seleccionada)
  
  # Paleta de colores por balota
  colores <- c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b")
  names(colores) <- c(paste0("Balota0", 1:5), "SuperBalota")
  
  plot_ly(
    data = datos_grafico,
    x = ~as.factor(Numero),
    y = ~Frecuencia,
    type = "bar",
    color = I(colores[balota_seleccionada]),
    hoverinfo = "text",
    text = ~paste("Número:", Numero, "<br>Frecuencia:", Frecuencia),
    marker = list(
      line = list(color = "rgb(8,48,107)", width = 1.5)
    )
  ) %>%
    layout(
      title = paste("Frecuencias -", balota_seleccionada),
      xaxis = list(title = "Número"),
      yaxis = list(title = "Frecuencia"),
      hoverlabel = list(bgcolor = "white")
    )
}