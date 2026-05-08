library(shiny)
library(dplyr)
library(ggplot2)
library(tidyr)
library(plotly)

shinyServer(function(input, output, session) {
  
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  # Cargar archivo de usuario de forma reactiva
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  datos_usuario <- reactive({
    req(input$file1)
    df <- read.csv(
      input$file1$datapath,
      header = input$header,
      sep = input$sep,
      quote = input$quote
    )
    names(df)[names(df) == "Calorías"] <- "calorias"
    df$Fecha <- as.POSIXct(df$Fecha)
    return(df)
  })
  
  # Actualizando el selectInput para Run Info
  observe({
    req(datos_usuario())  
    fechas <- unique(datos_usuario()$Fecha)
    updateSelectInput(session, "Fecha", choices = fechas)
  })
  
  # Actualizando el selectInput para Cardio Info
  observe({
    req(datos_usuario())  
    fechas <- unique(datos_usuario()$Fecha)
    updateSelectInput(session, "Fecha_i2", choices = fechas)
  })
  
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  # Mostrar tabla del archivo cargado
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  output$contents <- renderTable({
    df <- datos_usuario()
    if (input$disp == "head") head(df) else df
  })
  
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  # Actualizar inputs al seleccionar fecha (Run Info)
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  observeEvent(input$Fecha, {
    df <- datos_usuario()
    selected <- df %>% filter(Fecha == input$Fecha)
    if (nrow(selected) > 0) {
      updateNumericInput(session, "Distancia", value = selected$Distancia)
      updateTextInput(session, "Tiempo", value = selected$Tiempo)
      updateTextInput(session, "Ritmo.medio", value = selected$Ritmo.medio)
      updateNumericInput(session, "Cadencia.de.carrera.media", value = selected$Cadencia.de.carrera.media)
      updateNumericInput(session, "Longitud.media.de.zancada", value = selected$Longitud.media.de.zancada)
      updateTextInput(session, "calorias", value = selected$calorias)
      updateTextInput(session, "Frecuencia.cardiaca.media", value = selected$Frecuencia.cardiaca.media)
      updateTextInput(session, "TE.aeróbico", value = selected$TE.aeróbico)
    }
  })
  
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  # Actualizar inputs al seleccionar fecha (Cardio Info)
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  observeEvent(input$Fecha_i2, {
    df <- datos_usuario()
    selected <- df %>% filter(Fecha == input$Fecha_i2)
    if (nrow(selected) > 0) {
      # Los gráficos de temperatura y altura reaccionan directamente a input$Fecha_i2.
      # Aquí se podrían actualizar campos adicionales si se agregan al tab en el futuro.
    }
  })
  
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  # Funciones auxiliares para tiempo y ritmo
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  time_to_hours <- function(time) {
    t <- as.POSIXct(time, format = "%H:%M:%S", tz = "UTC")
    as.numeric(format(t, "%H")) + as.numeric(format(t, "%M"))/60 + as.numeric(format(t, "%S"))/3600
  }
  
  pace_to_seconds <- function(pace) {
    p <- as.POSIXct(pace, format = "%M:%S", tz = "UTC", origin = "1970-01-01")
    if (is.na(p)) return(NA)
    as.numeric(format(p, "%M"))*60 + as.numeric(format(p, "%S"))
  }
  
  seconds_to_pace <- function(sec) {
    p <- as.POSIXct(sec, origin = "1970-01-01", tz = "UTC")
    strftime(p, "%M:%S")
  }
  
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  # ValueBoxes (totales)
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  output$actividad_histograma <- renderPlotly({
    req(datos_usuario())
    
    df <- datos_usuario() %>% arrange(Fecha)
    
    # Tooltip enriquecido — ahora sí lo usa plotly via hovertext
    df$tooltip <- paste0(
      "<b>Fecha:</b> ", format(df$Fecha, "%Y-%m-%d"), "<br>",
      "<b>Distancia:</b> ", df$Distancia, " km<br>",
      "<b>Tiempo:</b> ", df$Tiempo, "<br>",
      "<b>Ritmo medio:</b> ", df$Ritmo.medio, "<br>",
      "<b>Cadencia media:</b> ", df$Cadencia.de.carrera.media, " pmm<br>",
      "<b>Longitud zancada:</b> ", df$Longitud.media.de.zancada, " m<br>",
      "<b>Calorías:</b> ", df$calorias, "<br>",
      "<b>FC media:</b> ", df$Frecuencia.cardiaca.media, " bpm<br>",
      "<b>TE aeróbico:</b> ", df$TE.aeróbico
    )
    
    p <- ggplot(df, aes(x = Fecha, y = Distancia, text = tooltip)) +
      geom_col(fill = "#1f77b4") +
      labs(title = "Actividades por fecha",
           x = "Fecha",
           y = "Distancia (km)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p, tooltip = "text")
  })
  
  
  output$total_activities_box <- renderValueBox({
    valueBox(nrow(datos_usuario()), "Total Activities", icon = icon("list"), color = "orange")
  })
  
  output$total_distance_box <- renderValueBox({
    valueBox(sum(datos_usuario()$Distancia), "Total Distance (km)", icon = icon("road"), color = "maroon")
  })
  
  output$total_time_box <- renderValueBox({
    horas <- sum(sapply(datos_usuario()$Tiempo, time_to_hours), na.rm = TRUE)
    valueBox(sprintf("%.2f", horas), "Total Time (hours)", icon = icon("clock"), color = "blue")
  })
  
  output$total_average_pace_box <- renderValueBox({
    paces <- sapply(datos_usuario()$Ritmo.medio, pace_to_seconds)
    promedio <- mean(paces, na.rm = TRUE)
    valueBox(seconds_to_pace(promedio), "Average Pace (mm:ss)", icon = icon("tachometer"), color = "green")
  })
  
  output$total_average_running_box <- renderValueBox({
    promedio <- mean(datos_usuario()$Cadencia.de.carrera.media, na.rm = TRUE)
    valueBox(signif(promedio, 4), "Avg Running Cadence (pmm)", icon = icon("heartbeat"), color = "purple")
  })
  
  output$total_average_stride_box <- renderValueBox({
    promedio <- mean(datos_usuario()$Longitud.media.de.zancada, na.rm = TRUE)
    valueBox(signif(promedio, 4), "Avg Stride Length (m)", icon = icon("shoe-prints"), color = "olive")
  })
  
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  # Gráficos de temperatura y altura (Cardio Info)
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  output$temperature_plot <- renderPlot({
    validate(need(input$Fecha_i2, "Por favor, carga un archivo CSV."))
    df <- datos_usuario() %>% filter(Fecha == input$Fecha_i2)
    df_long <- df %>% gather("Tipo", "Temperatura", Temperatura.mínima, Temperatura.máxima)
    ggplot(df_long, aes(x = Tipo, y = Temperatura, fill = Tipo)) +
      geom_bar(stat = "identity") +
      labs(title = "Temperaturas", y = "°C") +
      scale_fill_manual(values = c("#97ea36", "#b4d081")) +
      theme_minimal()
  })
  
  output$height_plot <- renderPlot({
    validate(need(input$Fecha_i2, "Por favor, carga un archivo CSV."))
    df <- datos_usuario() %>% filter(Fecha == input$Fecha_i2)
    df_long <- df %>% gather("Tipo", "Altura", Altura.mínima, Altura.máxima)
    ggplot(df_long, aes(x = Tipo, y = Altura, fill = Tipo)) +
      geom_bar(stat = "identity") +
      labs(title = "Alturas", y = "m") +
      scale_fill_manual(values = c("#c1440e", "#e97451")) +
      theme_minimal()
  })
  
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  # Tab: Comparar actividades
  #–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––#
  
  # Poblar los selectInputs de comparación con las fechas disponibles
  observe({
    req(datos_usuario())
    fechas <- unique(datos_usuario()$Fecha)
    updateSelectInput(session, "comp_fecha_1", choices = fechas)
    updateSelectInput(session, "comp_fecha_2", choices = fechas,
                      selected = if (length(fechas) > 1) fechas[2] else fechas[1])
  })
  
  # Helper: construye la tabla de resumen para una actividad
  tabla_resumen <- function(df, fecha) {
    row <- df %>% filter(Fecha == fecha)
    if (nrow(row) == 0) return(data.frame(Campo = character(), Valor = character()))
    data.frame(
      Campo = c("Fecha", "Distancia (km)", "Tiempo", "Ritmo medio",
                "Cadencia media (pmm)", "Longitud zancada (m)",
                "Calorías", "FC media (bpm)", "TE aeróbico"),
      Valor = c(
        format(row$Fecha[1], "%Y-%m-%d"),
        as.character(row$Distancia[1]),
        row$Tiempo[1],
        row$Ritmo.medio[1],
        as.character(row$Cadencia.de.carrera.media[1]),
        as.character(row$Longitud.media.de.zancada[1]),
        as.character(row$calorias[1]),
        as.character(row$Frecuencia.cardiaca.media[1]),
        as.character(row$TE.aeróbico[1])
      ),
      stringsAsFactors = FALSE
    )
  }
  
  output$tabla_actividad_1 <- renderTable({
    req(input$comp_fecha_1, datos_usuario())
    tabla_resumen(datos_usuario(), input$comp_fecha_1)
  })
  
  output$tabla_actividad_2 <- renderTable({
    req(input$comp_fecha_2, datos_usuario())
    tabla_resumen(datos_usuario(), input$comp_fecha_2)
  })
  
  # Gráfico comparativo: barras agrupadas de métricas numéricas
  output$comparison_plot <- renderPlotly({
    req(input$comp_fecha_1, input$comp_fecha_2, datos_usuario())
    
    df <- datos_usuario()
    r1 <- df %>% filter(Fecha == input$comp_fecha_1)
    r2 <- df %>% filter(Fecha == input$comp_fecha_2)
    if (nrow(r1) == 0 || nrow(r2) == 0) return(NULL)
    
    etiquetas <- c("Distancia (km)", "Cadencia (pmm)", "Longitud zancada (m)")
    val1 <- c(r1$Distancia[1], r1$Cadencia.de.carrera.media[1], r1$Longitud.media.de.zancada[1])
    val2 <- c(r2$Distancia[1], r2$Cadencia.de.carrera.media[1], r2$Longitud.media.de.zancada[1])
    
    comp_df <- data.frame(
      Metrica   = rep(etiquetas, 2),
      Valor     = c(val1, val2),
      Actividad = c(
        rep(format(r1$Fecha[1], "%Y-%m-%d"), length(etiquetas)),
        rep(format(r2$Fecha[1], "%Y-%m-%d"), length(etiquetas))
      )
    )
    
    p <- ggplot(comp_df, aes(x = Metrica, y = Valor, fill = Actividad)) +
      geom_bar(stat = "identity", position = "dodge") +
      labs(title = "Comparación de actividades", x = NULL, y = "Valor") +
      scale_fill_manual(values = c("#1f77b4", "#ff7f0e")) +
      theme_minimal()
    
    ggplotly(p)
  })
  
})