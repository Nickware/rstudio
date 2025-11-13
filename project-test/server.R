function(input, output, session) {
  
  # Reactive para datos crudos
  datos <- reactiveVal(NULL)
  error <- reactiveVal(NULL)
  
  # Función para cargar datos
  cargar_datos <- function() {
    tryCatch({
      datos(obtener_datos_reales())
      error(NULL)
    }, error = function(e) {
      error(e$message)
      datos(NULL)
    })
  }
  
  # Carga inicial
  observe({
    cargar_datos()
  })
  
  # Botón reintentar
  observeEvent(input$reintentar, {
    cargar_datos()
  })
  
  # Reactives para análisis
  frecuencias <- reactive({
    req(datos())
    calcular_frecuencias(datos())
  })
  
  datos_boxplot <- reactive({
    req(datos())
    preparar_datos_boxplot(datos())
  })
  
  series_temporales <- reactive({
    req(datos())
    preparar_series_temporales(datos())
  })
  
  estadisticas_posicion <- reactive({
    req(datos())
    calcular_estadisticas_posicion(datos())
  })
  
  medias_moviles <- reactive({
    req(datos())
    preparar_medias_moviles(datos(), ventana = input$ventana_movil %||% 15)
  })
  
  # === OUTPUTS PRINCIPALES ===
  
  # Tabla de datos crudos
  output$tabla_cruda <- renderDT({
    req(datos())
    datatable(
      mutate(datos(), Fecha = format(Fecha, "%d/%m/%Y")),
      options = list(scrollX = TRUE),
      rownames = FALSE
    )
  })
  
  # Fecha de actualización
  output$fecha_actualizacion <- renderText({
    format(Sys.Date(), "%d/%m/%Y")
  })
  
  # Tabla de frecuencias globales
  output$tabla_frecuencias <- renderDT({
    req(frecuencias())
    datatable(
      frecuencias() %>%
        pivot_wider(
          names_from = Numero,
          values_from = Frecuencia,
          values_fill = 0
        ),
      options = list(scrollX = TRUE)
    )
  })
  
  # Histograma
  output$histograma <- renderPlotly({
    req(frecuencias(), input$balota_seleccionada)
    
    frecuencias() %>%
      filter(Balota == input$balota_seleccionada) %>%
      plot_ly(
        x = ~as.factor(Numero),
        y = ~Frecuencia,
        type = "bar",
        marker = list(color = "steelblue")
      ) %>%
      layout(
        title = paste("Frecuencias -", input$balota_seleccionada),
        xaxis = list(title = "Número"),
        yaxis = list(title = "Frecuencia")
      )
  })
  
  # Selector de balota
  output$selector_balota <- renderUI({
    req(frecuencias())
    selectInput(
      "balota_seleccionada",
      "Selecciona balota:",
      choices = unique(frecuencias()$Balota)
    )
  })
  
  # Mensaje de estado
  output$status <- renderUI({
    if (!is.null(error())) {
      div(class = "alert alert-danger", error())
    } else if (is.null(datos())) {
      div(class = "alert alert-warning", "Cargando datos...")
    } else {
      div(class = "alert alert-success", 
          paste("Datos cargados:", nrow(datos()), "registros"))
    }
  })
  
  # === ANÁLISIS POR POSICIÓN ===
  
  # Boxplot de posiciones
  output$boxplot_posiciones <- renderPlotly({
    req(datos_boxplot())
    generar_boxplot_posiciones(datos_boxplot())
  })
  
  # Estadísticas del boxplot
  output$estadisticas_boxplot <- renderPrint({
    req(datos_boxplot())
    
    datos_boxplot() %>%
      group_by(Posicion) %>%
      summarise(
        Min = min(Numero),
        Q1 = quantile(Numero, 0.25),
        Mediana = median(Numero),
        Q3 = quantile(Numero, 0.75),
        Max = max(Numero),
        Media = mean(Numero),
        SD = sd(Numero),
        .groups = "drop"
    )
  })
  
  # === SERIES TEMPORALES ===
  
  # Selector de tipo de tendencia
  output$selector_tendencia <- renderUI({
    radioButtons(
      "tipo_tendencia",
      "Tipo de Análisis:",
      choices = c(
        "Promedios Acumulados" = "acumuladas",
        "Medias Móviles" = "moviles"
      ),
      selected = "acumuladas"
    )
  })
  
  # Slider para ventana de medias móviles
  output$slider_ventana <- renderUI({
    sliderInput("ventana_movil", "Ventana Medias Móviles:",
               min = 5, max = 50, value = 15, step = 5)
  })
  
  # Gráfico de tendencias
  output$grafico_tendencias <- renderPlotly({
    req(input$tipo_tendencia)
    
    if (input$tipo_tendencia == "acumuladas") {
      req(series_temporales())
      generar_grafico_series(series_temporales(), "acumuladas")
    } else {
      req(medias_moviles())
      generar_grafico_series(medias_moviles(), "moviles")
    }
  })
  
  # Series temporales (para pestaña simple)
  output$series_temporales <- renderPlotly({
    req(series_temporales())
    generar_grafico_series(series_temporales(), "acumuladas")
  })
  
  # === ANÁLISIS MULTIVARIADO ===
  
  # Heatmap de posición
  output$heatmap_posicion <- renderPlotly({
    req(estadisticas_posicion())
    generar_heatmap_posicion(estadisticas_posicion())
  })
  
  # Tabla de posición
  output$tabla_posicion <- renderDT({
    req(estadisticas_posicion())
    
    datatable(
      estadisticas_posicion() %>%
        select(-Frecuencia_Relativa) %>%
        pivot_wider(
          names_from = Numero,
          values_from = Frecuencia,
          values_fill = 0
        ),
      options = list(
        scrollX = TRUE,
        pageLength = 5,
        dom = 't'
      ),
      caption = "Frecuencia por Número y Posición"
    )
  })
  
  # Histograma por posición
  output$histograma_posicion <- renderPlotly({
    req(estadisticas_posicion())
    
    estadisticas_posicion() %>%
      plot_ly(
        x = ~Numero,
        y = ~Frecuencia,
        color = ~Posicion,
        type = "bar"
      ) %>%
      layout(
        title = "Comparación de Frecuencias por Posición",
        xaxis = list(title = "Número"),
        yaxis = list(title = "Frecuencia"),
        barmode = "group"
      )
  })
  
  # Descarga de datos de posición
  output$descargar_posicion <- downloadHandler(
    filename = "frecuencias_posicion.csv",
    content = function(file) {
      write.csv(estadisticas_posicion(), file, row.names = FALSE)
    }
  )
  
  # Botón actualizar análisis
  observeEvent(input$actualizar_analisis, {
    showNotification("Análisis actualizado", type = "message")
  })
}