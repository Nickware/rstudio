# modules/data_import_server.R
# Lógica del servidor para el módulo de ingesta de datos
# Versión: 3.0
# Última actualización: Junio 2026

library(shiny)
library(tidyverse)
library(DT)

source("R/detector_tipo.R")

dataImportServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    # ============================================================
    # REACTIVOS PRINCIPALES
    # ============================================================
    
    archivos_cargados_multi <- reactiveVal(list())
    datos_normalizados <- reactiveVal(NULL)
    datos_completos_individual <- reactiveVal(NULL)
    datos_completos_colectivo <- reactiveVal(NULL)
    
    # ============================================================
    # VALIDACIÓN: MODO INDIVIDUAL
    # ============================================================
    
    observeEvent(input$archivo_individual, {
      req(input$archivo_individual)
      
      df_completo <- read.csv(input$archivo_individual$datapath)
      datos_completos_individual(df_completo)
      df_preview <- head(df_completo, 10)
      
      validacion <- validar_estructura(df_completo, "individual")
      
      if(validacion$valido) {
        output$preview_individual <- renderDT({
          datatable(df_preview, 
                    options = list(scrollX = TRUE, pageLength = 5),
                    caption = htmltools::tags$caption(
                      style = 'caption-side: bottom; text-align: center;',
                      paste0('Mostrando 10 de ', nrow(df_completo), ' filas totales')
                    ))
        })
        
        output$info_estructura <- renderPrint({
          cat("📄 Archivo:", input$archivo_individual$name, "\n")
          cat(validacion$mensaje, "\n")
          cat("📏 Filas totales:", nrow(df_completo), "\n")
          cat("📊 Columnas:", ncol(df_completo), "\n")
          cat("👁️ Vista previa:", nrow(df_preview), "filas\n")
        })
        
        shinyjs::enable("procesar")
      } else {
        output$preview_individual <- renderDT({
          datatable(data.frame(Error = validacion$mensaje))
        })
        
        output$info_estructura <- renderPrint({
          cat(validacion$mensaje, "\n")
          cat("🔴 El archivo NO se puede procesar.\n")
        })
        
        shinyjs::disable("procesar")
        showNotification(validacion$mensaje, type = "error", duration = 8)
      }
    })
    
    # ============================================================
    # VALIDACIÓN: MODO COLECTIVO
    # ============================================================
    
    observeEvent(input$archivo_colectivo, {
      req(input$archivo_colectivo)
      
      df_completo <- read.csv(input$archivo_colectivo$datapath)
      datos_completos_colectivo(df_completo)
      df_preview <- head(df_completo, 10)
      
      validacion <- validar_estructura(df_completo, "colectivo")
      
      if(validacion$valido) {
        output$preview_colectivo <- renderDT({
          datatable(df_preview, 
                    options = list(scrollX = TRUE),
                    caption = htmltools::tags$caption(
                      style = 'caption-side: bottom; text-align: center;',
                      paste0('Mostrando 10 de ', nrow(df_completo), ' actividades totales')
                    ))
        })
        
        output$info_estructura <- renderPrint({
          cat("📄 Archivo:", input$archivo_colectivo$name, "\n")
          cat(validacion$mensaje, "\n")
          cat("📏 Actividades totales:", nrow(df_completo), "\n")
          cat("📊 Columnas:", ncol(df_completo), "\n")
          cat("👁️ Vista previa:", nrow(df_preview), "actividades\n")
        })
        
        shinyjs::enable("procesar")
      } else {
        output$preview_colectivo <- renderDT({
          datatable(data.frame(Error = validacion$mensaje))
        })
        
        output$info_estructura <- renderPrint({
          cat(validacion$mensaje, "\n")
          cat("🔴 El archivo NO se puede procesar.\n")
        })
        
        shinyjs::disable("procesar")
        showNotification(validacion$mensaje, type = "error", duration = 8)
      }
    })
    
    # ============================================================
    # VALIDACIÓN: MODO MÚLTIPLES INDIVIDUALES
    # ============================================================
    
    observeEvent(input$archivos_multi, {
      req(input$archivos_multi)
      
      archivos_lista <- list()
      errores <- list()
      info_archivos <- list()
      
      for(i in 1:nrow(input$archivos_multi)) {
        archivo <- input$archivos_multi[i, ]
        df_completo <- read.csv(archivo$datapath)
        filas_totales <- nrow(df_completo)
        
        df_sin_resumen <- df_completo
        if("Vueltas" %in% names(df_completo)) {
          df_sin_resumen <- df_completo %>% 
            filter(!grepl("Resumen", Vueltas, ignore.case = TRUE))
        }
        
        validacion <- validar_estructura(df_sin_resumen, "individual")
        
        info_archivos[[archivo$name]] <- list(
          total_filas = filas_totales,
          filas_utiles = nrow(df_sin_resumen),
          columnas = ncol(df_completo),
          tiene_resumen = any(grepl("Resumen", df_completo$Vueltas, ignore.case = TRUE))
        )
        
        if(validacion$valido) {
          archivos_lista[[archivo$name]] <- df_sin_resumen
        } else {
          errores[[archivo$name]] <- validacion$mensaje
        }
      }
      
      archivos_cargados_multi(archivos_lista)
      
      nombres_validos <- names(archivos_lista)
      etiquetas <- gsub("\\.csv$", "", nombres_validos, ignore.case = TRUE)
      
      if(length(nombres_validos) > 0) {
        updateCheckboxGroupInput(session, "seleccion_multi",
                                 choices = setNames(nombres_validos, etiquetas),
                                 selected = nombres_validos)
      }
      
      output$info_estructura <- renderPrint({
        cat("📁 Archivos cargados:", nrow(input$archivos_multi), "\n")
        cat("✅ Válidos:", length(archivos_lista), "\n")
        cat("❌ Inválidos:", length(errores), "\n\n")
        
        if(length(errores) > 0) {
          cat("⚠️ ARCHIVOS RECHAZADOS:\n")
          for(nombre in names(errores)) {
            cat("  -", nombre, "\n")
          }
        }
        
        if(length(archivos_lista) > 0) {
          cat("\n✅ ARCHIVOS ACEPTADOS:\n")
          for(nombre in nombres_validos) {
            info <- info_archivos[[nombre]]
            cat("  -", nombre, "\n")
            cat("    Filas totales:", info$total_filas)
            if(info$tiene_resumen) cat(" (incluye 'Resumen')")
            cat("\n    Filas útiles:", info$filas_utiles, "\n")
            cat("    Columnas:", info$columnas, "\n")
          }
        }
      })
      
      if(length(archivos_lista) > 0) {
        shinyjs::enable("procesar")
        showNotification(paste("✅", length(archivos_lista), "archivos válidos"), 
                         type = "message", duration = 5)
      } else {
        shinyjs::disable("procesar")
        showNotification("❌ Ningún archivo válido", type = "error", duration = 8)
      }
    })
    
    # ============================================================
    # VISTA PREVIA: MÚLTIPLES ARCHIVOS
    # ============================================================
    
    output$preview_multi <- renderUI({
      req(archivos_cargados_multi())
      
      archivos <- archivos_cargados_multi()
      
      tabs <- lapply(names(archivos), function(nombre_archivo) {
        df_completo <- archivos[[nombre_archivo]]
        df_preview <- head(df_completo, 10)
        
        tabPanel(
          title = nombre_archivo,
          fluidRow(
            column(12,
                   h4(paste("Vista previa:", nombre_archivo)),
                   p(paste("Filas totales:", nrow(df_completo), "| Columnas:", ncol(df_completo))),
                   p(paste("Mostrando:", nrow(df_preview), "de", nrow(df_completo), "filas")),
                   DTOutput(session$ns(paste0("preview_", gsub("\\.|\\s", "_", nombre_archivo))))
            )
          )
        )
      })
      
      do.call(tabsetPanel, c(tabs, list(type = "tabs")))
    })
    
    observe({
      req(archivos_cargados_multi())
      
      archivos <- archivos_cargados_multi()
      
      for(nombre_archivo in names(archivos)) {
        local({
          df_completo <- archivos[[nombre_archivo]]
          df_preview <- head(df_completo, 10)
          output_id <- paste0("preview_", gsub("\\.|\\s", "_", nombre_archivo))
          
          output[[output_id]] <- renderDT({
            datatable(df_preview, 
                      options = list(scrollX = TRUE, pageLength = 5, dom = 'Bfrtip'),
                      caption = htmltools::tags$caption(
                        style = 'caption-side: bottom; text-align: center;',
                        paste0('Mostrando 10 de ', nrow(df_completo), ' filas útiles')
                      ))
          })
        })
      }
    })
    
    # ============================================================
    # PROCESAMIENTO PRINCIPAL
    # ============================================================
    
    observeEvent(input$procesar, {
      showNotification("Procesando datos...", type = "message")
      
      datos_lista <- list()
      
      if(input$modo_carga == "individual") {
        req(datos_completos_individual())
        df <- datos_completos_individual()
        if("Vueltas" %in% names(df)) {
          df <- df %>% filter(!grepl("Resumen", Vueltas, ignore.case = TRUE))
        }
        id_actividad <- gsub("\\.csv$", "", input$archivo_individual$name, ignore.case = TRUE)
        df_normalizado <- normalizar_datos(df, "individual", id_actividad)
        df_normalizado$sujeto <- input$sujeto
        df_normalizado$superficie <- input$superficie
        datos_lista[[id_actividad]] <- df_normalizado
      }
      
      else if(input$modo_carga == "colectivo") {
        req(datos_completos_colectivo())
        df <- datos_completos_colectivo()
        for(j in 1:nrow(df)) {
          df_fila <- df[j, , drop = FALSE]
          df_normalizado <- normalizar_datos(df_fila, "colectivo",
                                             id_actividad = paste("act_", j, sep = ""))
          df_normalizado$sujeto <- input$sujeto
          df_normalizado$superficie <- input$superficie
          datos_lista[[paste("actividad_", j, sep = "")]] <- df_normalizado
        }
      }
      
      else if(input$modo_carga == "multi_individual") {
        req(archivos_cargados_multi(), input$seleccion_multi)
        archivos_completos <- archivos_cargados_multi()
        archivos_a_procesar <- names(archivos_completos)[names(archivos_completos) %in% input$seleccion_multi]
        for(id_actividad in archivos_a_procesar) {
          df <- archivos_completos[[id_actividad]]
          df_normalizado <- normalizar_datos(df, "individual", id_actividad)
          df_normalizado$sujeto <- input$sujeto
          df_normalizado$superficie <- input$superficie
          datos_lista[[id_actividad]] <- df_normalizado
        }
      }
      
      if(length(datos_lista) > 0) {
        datos_combinados <- bind_rows(datos_lista)
        datos_normalizados(datos_combinados)
        
        output$resumen_carga <- renderPrint({
          cat("✅ Procesados:", length(datos_lista), "archivos\n")
          cat("📊 Registros totales:", nrow(datos_combinados), "\n")
          cat("🏃 Sujeto:", unique(datos_combinados$sujeto), "\n")
          cat("🛤️ Superficie:", unique(datos_combinados$superficie), "\n")
        })
        
        showNotification(paste("✅", length(datos_lista), "archivos procesados con", 
                               nrow(datos_combinados), "registros"), 
                         type = "message", duration = 5)
      } else {
        showNotification("❌ No se procesaron datos válidos", type = "error", duration = 5)
      }
    })
    
    # ============================================================
    # OUTPUTS: DATOS NORMALIZADOS Y ESTADÍSTICAS
    # ============================================================
    
    output$preview_normalizado <- renderDT({
      req(datos_normalizados())
      datatable(head(datos_normalizados(), 20), 
                options = list(scrollX = TRUE, pageLength = 10),
                caption = htmltools::tags$caption(
                  style = 'caption-side: bottom; text-align: center;',
                  paste0('Mostrando 20 de ', nrow(datos_normalizados()), ' registros')
                ))
    })
    
    output$distribucion_metricas <- renderPlot({
      req(datos_normalizados())
      datos <- datos_normalizados()
      
      metricas_interes <- c("tiempo_contacto_ms", "cadencia_media_spm", 
                            "longitud_zancada_cm", "oscilacion_vertical_cm",
                            "ritmo_medio_min_km", "fc_media_bpm")
      metricas_presentes <- intersect(metricas_interes, names(datos))
      
      if(length(metricas_presentes) > 0) {
        datos %>%
          select(all_of(metricas_presentes)) %>%
          pivot_longer(everything(), names_to = "metrica", values_to = "valor") %>%
          ggplot(aes(x = valor, fill = metrica)) +
          geom_histogram(bins = 30, alpha = 0.7, show.legend = FALSE) +
          facet_wrap(~metrica, scales = "free", ncol = 2) +
          theme_minimal() +
          labs(title = "Distribución de métricas normalizadas")
      } else {
        ggplot() + annotate("text", x = 0.5, y = 0.5, 
                            label = "No hay métricas disponibles") + theme_void()
      }
    })
    
    output$evolucion_temporal <- renderPlot({
      req(datos_normalizados())
      datos <- datos_normalizados()
      
      if(all(c("semana", "tiempo_contacto_ms") %in% names(datos))) {
        datos %>%
          group_by(semana, superficie) %>%
          summarise(tiempo_contacto_mean = mean(tiempo_contacto_ms, na.rm = TRUE),
                    .groups = "drop") %>%
          ggplot(aes(x = semana, y = tiempo_contacto_mean, color = superficie)) +
          geom_line(size = 1.2) + geom_point(size = 3) +
          theme_minimal() +
          labs(title = "Evolución del tiempo de contacto",
               x = "Semana", y = "Tiempo de contacto (ms)")
      } else {
        ggplot() + annotate("text", x = 0.5, y = 0.5, 
                            label = "Se necesitan datos con 'semana' y 'tiempo_contacto_ms'") +
          theme_void()
      }
    })
    
    # ============================================================
    # RETORNAR DATOS
    # ============================================================
    
    return(datos_normalizados)
    
  })
}