# R/detector_tipo.R
# Detección de tipo de archivo y normalización de datos
# Versión: 2.1
# Última actualización: Junio 2026

# ============================================================
# FUNCIÓN: detectar_tipo_archivo
# Detecta si el archivo es individual o colectivo
# ============================================================

detectar_tipo_archivo <- function(df) {
  nombres_columnas <- names(df)
  
  # Patrones para detectar individual
  patrones_individual <- c("Vueltas", "GAP.medio", "Potencia.media")
  coincidencias_individual <- sum(sapply(patrones_individual, function(p) {
    any(grepl(p, nombres_columnas, ignore.case = TRUE))
  }))
  
  # Patrones para detectar colectivo
  patrones_colectivo <- c("Tipo.de.actividad", "Fecha", "Training.Stress.Score")
  coincidencias_colectivo <- sum(sapply(patrones_colectivo, function(p) {
    any(grepl(p, nombres_columnas, ignore.case = TRUE))
  }))
  
  if(coincidencias_individual >= 2) {
    return("individual")
  } else if(coincidencias_colectivo >= 2) {
    return("colectivo")
  } else {
    return("desconocido")
  }
}

# ============================================================
# FUNCIÓN: validar_estructura
# Valida que el archivo tenga la estructura esperada
# ============================================================

validar_estructura <- function(df, tipo_esperado) {
  nombres_columnas <- names(df)
  
  if(tipo_esperado == "individual") {
    columnas_requeridas <- c(
      "Vueltas", "Tiempo", "Distancia",
      "Ritmo.medio", "Frecuencia.cardiaca.media",
      "Cadencia.de.carrera.media"
    )
    
    presentes <- columnas_requeridas %in% nombres_columnas
    
    if(all(presentes)) {
      return(list(
        valido = TRUE,
        tipo_detectado = "individual",
        mensaje = paste("✅ Estructura individual válida (", ncol(df), " columnas)"),
        advertencias = NULL
      ))
    } else {
      faltantes <- columnas_requeridas[!presentes]
      return(list(
        valido = FALSE,
        tipo_detectado = "individual",
        mensaje = paste("❌ Error: Archivo no tiene estructura individual.\n",
                        "Columnas faltantes:", paste(faltantes, collapse = ", ")),
        advertencias = faltantes
      ))
    }
    
  } else if(tipo_esperado == "colectivo") {
    patrones_colectivo <- c("Tipo.de.actividad", "Fecha", "Distancia",
                            "Tiempo", "Frecuencia.cardiaca.media",
                            "Cadencia.de.carrera.media")
    
    presentes <- sapply(patrones_colectivo, function(p) {
      any(grepl(p, nombres_columnas, ignore.case = TRUE))
    })
    
    if(sum(presentes) >= 4 && nrow(df) >= 30) {
      return(list(
        valido = TRUE,
        tipo_detectado = "colectivo",
        mensaje = paste("✅ Estructura colectiva válida (", nrow(df), " actividades)"),
        advertencias = NULL
      ))
    } else {
      return(list(
        valido = FALSE,
        tipo_detectado = "colectivo",
        mensaje = paste("❌ Error: Archivo no tiene estructura colectiva.\n",
                        "Coincidencia:", sum(presentes), "/6 patrones\n",
                        "Filas:", nrow(df), "(mínimo 30)"),
        advertencias = NULL
      ))
    }
  }
}

# ============================================================
# FUNCIÓN: normalizar_datos
# Normaliza los datos a un formato común
# ============================================================

`%||%` <- function(a, b) {
  if (!is.null(a)) a else b
}

normalizar_datos <- function(df, tipo, id_actividad = NULL) {
  
  if(tipo == "individual") {
    df_normalizado <- df %>%
      mutate(
        actividad_id = id_actividad %||% paste("ind_", row_number(), sep = ""),
        tipo_dato = "individual",
        fecha = NA,
        semana = NA,
        
        vuelta = Vueltas,
        tiempo_seg = Tiempo,
        distancia_km = Distancia,
        ritmo_medio_min_km = `Ritmo.medio`,
        gap_medio = `GAP.medio`,
        fc_media_bpm = `Frecuencia.cardiaca.media`,
        fc_max_bpm = `FC.máxima`,
        cadencia_media_spm = `Cadencia.de.carrera.media`,
        cadencia_max_spm = `Cadencia.de.carrera.máxima`,
        tiempo_contacto_ms = `Tiempo.medio.de.contacto.con.el.suelo`,
        equilibrio_tcs_pct = `Equilibrio.de.TCS.medio`,
        longitud_zancada_cm = `Longitud.media.de.zancada`,
        oscilacion_vertical_cm = `Oscilación.vertical.media`,
        relacion_vertical_pct = `Relación.vertical.media`,
        potencia_media_w = `Potencia.media`,
        potencia_max_w = `Potencia.máxima`,
        wkg_media = `Media.de.W.kg`,
        wkg_max = `Máximo.de.W.kg`,
        ascenso_m = `Ascenso.total`,
        descenso_m = `Descenso.total`,
        calorias = Calorías,
        temperatura_media_c = `Temperatura.media`,
        ritmo_optimo = `Ritmo.óptimo`,
        tiempo_movimiento_seg = `Tiempo.en.movimiento`,
        ritmo_movimiento = `Ritmo.medio.en.movimiento`,
        perdida_velocidad = `Pérdida.de.velocidad.de.paso.media`,
        porcentaje_perdida = `Porcentaje.de.pérdida.de.velocidad.de.paso.media`
      )
    
  } else if(tipo == "colectivo") {
    df_normalizado <- df %>%
      mutate(
        actividad_id = id_actividad %||% paste("col_", row_number(), sep = ""),
        tipo_dato = "colectivo",
        fecha = as.Date(Fecha),
        semana = NA,
        
        distancia_km = Distancia,
        tiempo_seg = Tiempo,
        fc_media_bpm = `Frecuencia.cardiaca.media`,
        fc_max_bpm = `FC.máxima`,
        cadencia_media_spm = `Cadencia.de.carrera.media`,
        cadencia_max_spm = `Cadencia.de.carrera.máxima`,
        ritmo_medio_min_km = `Ritmo.medio`,
        tiempo_contacto_ms = `Tiempo.medio.de.contacto.con.el.suelo`,
        longitud_zancada_cm = `Longitud.media.de.zancada`,
        oscilacion_vertical_cm = `Oscilación.vertical.media`,
        relacion_vertical_pct = `Relación.vertical.media`,
        ascenso_m = `Ascenso.total`,
        descenso_m = `Descenso.total`,
        calorias = Calorías,
        temperatura_media_c = NA
      )
  }
  
  return(df_normalizado)
}