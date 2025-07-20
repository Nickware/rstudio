function(input, output, session) {
  # Reactive para datos crudos
  datos <- reactiveVal(NULL)
  error <- reactiveVal(NULL)
  
  # Carga de datos
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
  observe(cargar_datos())
  
  # Botón reintentar
  observeEvent(input$reintentar, cargar_datos())
  
  # Reactive para frecuencias
  frecuencias <- reactive({
    req(datos())
    calcular_frecuencias(datos())
  })
  
  # Tabla de datos crudos
  output$tabla_cruda <- renderDT({
    req(datos())
    datatable(
      mutate(datos(), Fecha = format(Fecha, "%d/%m/%Y")),
      options = list(scrollX = TRUE),
      rownames = FALSE
    )
  })
  
  # Tabla de frecuencias
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
  
  # Gráfico de frecuencias
  output$histograma <- renderPlotly({
    req(frecuencias(), input$balota_seleccionada)
    generar_grafico_interactivo(frecuencias(), input$balota_seleccionada)
  })
  
  # Selector con colores representativos
  output$selector_balota <- renderUI({
    req(frecuencias())
    selectInput(
      "balota_seleccionada",
      "Selecciona una balota:",
      choices = unique(frecuencias()$Balota),
      selectize = FALSE
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
}