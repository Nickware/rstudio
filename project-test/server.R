function(input, output, session) {
  # observe({
  #   print("Estructura de los datos: ")
  #   str(datos())
  #   print("Primeras filas: ")
  #   print(head(datos()))
  # })
  
  # Usamos reactiveVal para almacenar datos y estado
  datos <- reactiveVal(NULL)
  error <- reactiveVal(NULL)
  
  # Función para cargar datos (reutilizable)
  cargar_datos <- function() {
    tryCatch({
      datos(obtener_datos_reales())  # Llama a tu función de global.R
      error(NULL)
    }, error = function(e) {
      error(e$message)
      datos(NULL)
    })
  }
  
  # Carga inicial al iniciar la app
  observe({
    cargar_datos()
  })
  
  # Manejador del botón reintentar 
  observeEvent(input$reintentar, {
    cargar_datos()
  })
  
  # Renderizado de la tabla 
  output$tabla_cruda <- renderDT({
    req(datos())
    
    datatable(
      datos() %>%
        mutate(Fecha = format(as.Date(Fecha),"%d/%m/%Y")),  # Conversión directa en R
      options = list(scrollX = TRUE),
      rownames = FALSE
    )
  })
  
  # Mensaje de estado
  output$status <- renderUI({
    if (!is.null(error())) {
      div(class = "alert alert-danger",
          h4("Error al cargar datos"),
          p(error()),
          p("Por favor intenta nuevamente."))
    } else if (is.null(datos())) {
      div(class = "alert alert-warning",
          "Cargando datos...")
    } else {
      div(class = "alert alert-success",
          paste("Datos cargados:", nrow(datos()), "registros"))
    }
  })
}