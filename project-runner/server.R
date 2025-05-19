library(shiny)
library(dplyr)
library(ggplot2)
library(tidyr)

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
      # updateTextInput(session, "calorias", value = selected$calorias)
      # updateTextInput(session, "Frecuencia.cardiaca.media", value = selected$Frecuencia.cardiaca.media)
      # updateTextInput(session, "TE.aeróbico", value = selected$TE.aeróbico)
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
  
})