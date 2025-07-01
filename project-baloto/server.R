library(shiny)
library(tidyverse)
library(lubridate)

# ---- Funciones de Análisis (Modularizado) ----
source("global.R")

function(input, output, session) {
  # Paso 1: Cargar datos filtrados
  datos <- eventReactive(input$cargar, {
    req(input$rango_fechas)
    
    # Simulación de scraping (en producción reemplazar con scrapear_baloto())
    datos_ejemplo <- tibble(
      Fecha = seq(input$rango_fechas[1], input$rango_fechas[2], by = "day"),
      Balota01 = sample(1:43, length(Fecha), replace = TRUE),
      Balota02 = sample(1:43, length(Fecha), replace = TRUE),
      Balota03 = sample(1:43, length(Fecha), replace = TRUE),
      Balota04 = sample(1:43, length(Fecha), replace = TRUE),
      Balota05 = sample(1:43, length(Fecha), replace = TRUE),
      SuperBalota = sample(1:16, length(Fecha), replace = TRUE)
    )
    
    return(datos_ejemplo)
  })
  
  # Paso 2: Calcular frecuencias
  frecuencias <- reactive({
    req(datos())
    calcular_frecuencias(datos())
  })
  
  # ---- Outputs ----
  # Resumen de frecuencias
  output$resumen_frecuencias <- renderTable({
    frecuencias() %>%
      group_by(Balota) %>%
      summarise(
        Mínimo = min(Numero),
        Máximo = max(Numero),
        Frec_Promedio = mean(n),
        .groups = "drop"
      )
  })
  
  # Gráfico de frecuencias
  output$grafico_frecuencias <- renderPlot({
    req(frecuencias())
    graficar_frecuencias(frecuencias())
  })
  
  # Test de uniformidad
  output$test_uniformidad <- renderPrint({
    req(frecuencias())
    validar_uniformidad(frecuencias())
  })
}