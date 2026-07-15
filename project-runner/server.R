# ══════════════════════════════════════════════════════════════════════════════
# server.R — Running Biomechanics Dashboard
# Arquitectura: dos capas reactivas derivadas de archivos .fit
#   · sesiones()    → resumen por sesión (1 fila por .fit)
#   · telemetria()  → lista de dataframes con records por segundo
# ══════════════════════════════════════════════════════════════════════════════

library(shiny)
library(shinydashboard)
library(dplyr)
library(tidyr)
library(ggplot2)
library(plotly)
library(lubridate)

shinyServer(function(input, output, session) {

  # ────────────────────────────────────────────────────────────────────────────
  # HELPERS — conversión de unidades
  # Garmin almacena velocidad en m/s, distancia en m, posición en semicírculos
  # ────────────────────────────────────────────────────────────────────────────
  mps_to_pace <- function(mps) {
    # metros/segundo → string "mm:ss" por km
    if (is.na(mps) || mps == 0) return(NA_character_)
    secs_per_km <- 1000 / mps
    sprintf("%d:%02d", as.integer(secs_per_km %/% 60), as.integer(secs_per_km %% 60))
  }

  semicircles_to_deg <- function(sc) sc * (180 / 2^31)

  seconds_to_hms <- function(sec) {
    sec <- as.integer(sec)
    sprintf("%02d:%02d:%02d", sec %/% 3600, (sec %% 3600) %/% 60, sec %% 60)
  }

  pace_str_to_secs <- function(pace_str) {
    # "mm:ss" → segundos numéricos (para promediar correctamente)
    parts <- strsplit(pace_str, ":")[[1]]
    if (length(parts) != 2) return(NA_real_)
    as.numeric(parts[1]) * 60 + as.numeric(parts[2])
  }

  secs_to_pace_str <- function(sec) {
    sprintf("%d:%02d", as.integer(sec %/% 60), as.integer(sec %% 60))
  }

  # ────────────────────────────────────────────────────────────────────────────
  # CAPA 0 — Archivos cargados
  # fileInput con multiple = TRUE acepta N archivos .fit simultáneamente
  # ────────────────────────────────────────────────────────────────────────────
  fit_paths <- reactive({
    req(input$fit_files)
    # Devuelve un dataframe con columnas: name, datapath
    input$fit_files
  })

  # ────────────────────────────────────────────────────────────────────────────
  # PARSER — lee un único .fit y devuelve lista(resumen, records, laps)
  # Aislado para poder testearlo independientemente y reutilizarlo
  # ────────────────────────────────────────────────────────────────────────────
  # ────────────────────────────────────────────────────────────────────────────
  # PARSER NATIVO .fit — sin dependencias externas
  # Implementa lectura del protocolo FIT (Flexible and Interoperable Data Transfer)
  # Referencia: Garmin FIT Protocol SDK
  # ────────────────────────────────────────────────────────────────────────────

  # Epoch de Garmin: los timestamps FIT cuentan desde 1989-12-31 00:00:00 UTC
  FIT_EPOCH <- as.POSIXct("1989-12-31 00:00:00", tz = "UTC")

  # Tipos de datos FIT → bytes y signo
  fit_base_types <- list(
    `0x00` = list(name="enum",    size=1L, signed=FALSE),
    `0x01` = list(name="sint8",   size=1L, signed=TRUE),
    `0x02` = list(name="uint8",   size=1L, signed=FALSE),
    `0x83` = list(name="sint16",  size=2L, signed=TRUE),
    `0x84` = list(name="uint16",  size=2L, signed=FALSE),
    `0x85` = list(name="sint32",  size=4L, signed=TRUE),
    `0x86` = list(name="uint32",  size=4L, signed=FALSE),
    `0x07` = list(name="string",  size=1L, signed=FALSE),
    `0x88` = list(name="float32", size=4L, signed=FALSE),
    `0x89` = list(name="float64", size=8L, signed=FALSE),
    `0x0A` = list(name="uint8z",  size=1L, signed=FALSE),
    `0x8B` = list(name="uint16z", size=2L, signed=FALSE),
    `0x8C` = list(name="uint32z", size=4L, signed=FALSE),
    `0x0D` = list(name="byte",    size=1L, signed=FALSE),
    `0x8E` = list(name="sint64",  size=8L, signed=TRUE),
    `0x8F` = list(name="uint64",  size=8L, signed=FALSE),
    `0x90` = list(name="uint64z", size=8L, signed=FALSE)
  )

  # Números de campo globales FIT para mensajes "record" (mesg_num=20) y "lap" (mesg_num=19)
  # Solo los campos que necesitamos para el análisis biomecánico
  fit_field_defs <- list(
    # record (mesg_num = 20)
    `20` = list(
      `253` = list(name="timestamp",      scale=1,      offset=0, unit="s"),
      `0`   = list(name="position_lat",   scale=1,      offset=0, unit="semicircles"),
      `1`   = list(name="position_long",  scale=1,      offset=0, unit="semicircles"),
      `2`   = list(name="altitude",       scale=5,      offset=500, unit="m"),
      `3`   = list(name="heart_rate",     scale=1,      offset=0, unit="bpm"),
      `4`   = list(name="cadence",        scale=1,      offset=0, unit="rpm"),
      `5`   = list(name="distance",       scale=100,    offset=0, unit="m"),
      `6`   = list(name="speed",          scale=1000,   offset=0, unit="m/s"),
      `13`  = list(name="temperature",    scale=1,      offset=0, unit="C"),
      `53`  = list(name="fractional_cadence", scale=128, offset=0, unit="rpm")
    ),
    # lap (mesg_num = 19)
    `19` = list(
      `253` = list(name="timestamp",           scale=1,    offset=0, unit="s"),
      `7`   = list(name="total_elapsed_time",  scale=1000, offset=0, unit="s"),
      `8`   = list(name="total_timer_time",    scale=1000, offset=0, unit="s"),
      `9`   = list(name="total_distance",      scale=100,  offset=0, unit="m"),
      `11`  = list(name="total_calories",      scale=1,    offset=0, unit="kcal"),
      `15`  = list(name="avg_heart_rate",      scale=1,    offset=0, unit="bpm"),
      `16`  = list(name="max_heart_rate",      scale=1,    offset=0, unit="bpm"),
      `18`  = list(name="avg_cadence",         scale=1,    offset=0, unit="rpm"),
      `20`  = list(name="avg_speed",           scale=1000, offset=0, unit="m/s"),
      `21`  = list(name="max_speed",           scale=1000, offset=0, unit="m/s"),
      `40`  = list(name="avg_step_length",     scale=10,   offset=0, unit="mm")
    )
  )

  read_uint8  <- function(con) readBin(con, "integer", n=1, size=1, signed=FALSE, endian="little")
  read_uint16 <- function(con, end="little") readBin(con, "integer", n=1, size=2, signed=FALSE, endian=end)
  read_uint32 <- function(con, end="little") readBin(con, "integer", n=1, size=4, signed=FALSE, endian=end)
  read_sint32 <- function(con, end="little") readBin(con, "integer", n=1, size=4, signed=TRUE,  endian=end)

  read_fit_field_value <- function(con, base_type_id, size, endian) {
    key  <- sprintf("0x%02X", base_type_id)
    info <- fit_base_types[[key]]
    if (is.null(info)) { readBin(con, "raw", n=size); return(NA_real_) }
    n_elem <- size %/% info$size
    if (info$name == "string") {
      raw_bytes <- readBin(con, "raw", n=size)
      return(rawToChar(raw_bytes[raw_bytes != as.raw(0)]))
    }
    if (info$name %in% c("float32","float64")) {
      bits <- if (info$name=="float32") 4L else 8L
      return(readBin(con, "double", n=n_elem, size=bits, endian=endian)[1])
    }
    if (info$name %in% c("sint8","sint16","sint32","sint64")) {
      return(readBin(con, "integer", n=n_elem, size=info$size, signed=TRUE, endian=endian)[1])
    }
    # uint — readBin no soporta uint64 directamente, usar integer con workaround
    if (info$size <= 4L) {
      return(readBin(con, "integer", n=n_elem, size=info$size, signed=FALSE, endian=endian)[1])
    }
    # uint64: leer como 8 bytes raw
    raw_val <- readBin(con, "raw", n=size)
    return(NA_real_)
  }

  parse_fit <- function(path, nombre_archivo) {
    tryCatch({
      con <- file(path, "rb")
      on.exit(close(con))

      # ── Cabecera FIT ──────────────────────────────────────────────────────
      # -- Cabecera FIT: profile leido byte a byte para evitar warning uint32
      header_size <- read_uint8(con)
      protocol    <- read_uint8(con)
      profile_lo  <- read_uint8(con)
      profile_hi  <- read_uint8(con)
      raw4      <- readBin(con, "raw", n=4)
      data_size <- sum(as.numeric(as.integer(raw4)) * 256^(0:3))
      magic_str <- rawToChar(readBin(con, "raw", n=4))
      if (magic_str != ".FIT") stop("Archivo no valido, magic: '", magic_str, "'")
      extra <- as.integer(header_size) - 12L
      if (extra > 0) readBin(con, "raw", n=extra)

      # ── Lectura de mensajes ───────────────────────────────────────────────
      local_defs  <- list()   # definiciones de mensajes locales
      records_lst <- list()
      laps_lst    <- list()
      bytes_read  <- 0L

      while (bytes_read < data_size) {
        record_hdr <- read_uint8(con)
        bytes_read <- bytes_read + 1L
        if (length(record_hdr) == 0) break

        # Protocolo FIT — decodificación correcta del header byte:
        # bit 7: 1 = compressed timestamp, 0 = normal
        # bit 6: 1 = definition message,   0 = data message  (cuando bit7=0)
        # bit 5: 1 = tiene developer fields               (cuando bit7=0)
        # bits 3-0: local message number
        is_compressed <- bitwAnd(record_hdr, 0x80) != 0

        if (is_compressed) {
          # Compressed timestamp — bits 5-4 = local msg num
          local_num <- bitwAnd(bitwShiftR(record_hdr, 5L), 0x03)
          def <- local_defs[[as.character(local_num)]]
          if (!is.null(def)) {
            row_size <- sum(sapply(def$fields, function(f) f$size))
            readBin(con, "raw", n=row_size)
            bytes_read <- bytes_read + row_size
          }
          next
        }

        # Normal header
        is_definition <- bitwAnd(record_hdr, 0x40) != 0  # bit 6
        has_dev       <- bitwAnd(record_hdr, 0x20) != 0  # bit 5
        local_num     <- bitwAnd(record_hdr, 0x0F)       # bits 3-0

        if (is_definition) {
          # ── Mensaje de definición ─────────────────────────────────────────
          readBin(con, "raw", n=1)   # reserved
          bytes_read <- bytes_read + 1L
          arch     <- read_uint8(con); bytes_read <- bytes_read + 1L
          endian   <- if (arch == 1L) "big" else "little"
          mesg_num <- read_uint16(con, endian); bytes_read <- bytes_read + 2L
          n_fields <- read_uint8(con); bytes_read <- bytes_read + 1L

          fields <- vector("list", n_fields)
          for (i in seq_len(n_fields)) {
            fnum  <- read_uint8(con)
            fsize <- read_uint8(con)
            ftype <- read_uint8(con)
            bytes_read <- bytes_read + 3L
            fields[[i]] <- list(num=fnum, size=fsize, type=ftype)
          }

          if (has_dev) {
            n_dev <- read_uint8(con); bytes_read <- bytes_read + 1L
            for (i in seq_len(n_dev)) {
              readBin(con, "raw", n=3); bytes_read <- bytes_read + 3L
            }
          }

          local_defs[[as.character(local_num)]] <- list(
            mesg_num = mesg_num, endian = endian, fields = fields
          )

        } else {
          # ── Mensaje de datos ──────────────────────────────────────────────
          def <- local_defs[[as.character(local_num)]]
          if (is.null(def)) next

          row <- list()
          for (f in def$fields) {
            val        <- read_fit_field_value(con, f$type, f$size, def$endian)
            bytes_read <- bytes_read + f$size

            mesg_key  <- as.character(def$mesg_num)
            field_key <- as.character(f$num)
            fdef      <- fit_field_defs[[mesg_key]][[field_key]]

            if (!is.null(fdef) && !is.null(val) && length(val) > 0 && !is.na(val)) {
              # Valores inválidos (sentinel) según spec FIT
              invalid <- switch(sprintf("0x%02X", bitwAnd(f$type, 0xFF)),
                `0x86` = 2147483647L,   # uint32 (R lo trata como sint32)
                `0x84` = 65535L,        # uint16
                `0x02` = 255L,          # uint8
                `0x85` = -2147483648L,  # sint32
                `0x83` = -32768L,       # sint16
                `0x01` = 127L,          # sint8
                NA
              )
              is_invalid <- !is.null(invalid) && !is.na(invalid) && val == invalid
              if (!is_invalid) {
                row[[fdef$name]] <- (as.numeric(val) / fdef$scale) - fdef$offset
              } else {
                row[[fdef$name]] <- NA_real_
              }
            }
          }

          if (def$mesg_num == 20L && length(row) > 0) {
            records_lst[[length(records_lst) + 1L]] <- row
          } else if (def$mesg_num == 19L && length(row) > 0) {
            laps_lst[[length(laps_lst) + 1L]] <- row
          }
        }
      }

      if (length(records_lst) == 0) stop("No se encontraron records en el archivo .fit")

      # ── Construir dataframe de records ────────────────────────────────────
      all_keys <- unique(unlist(lapply(records_lst, names)))
      rec <- as.data.frame(
        setNames(
          lapply(all_keys, function(k)
            sapply(records_lst, function(r) if (!is.null(r[[k]])) r[[k]] else NA_real_)
          ),
          all_keys
        ),
        stringsAsFactors = FALSE
      )

      # Convertir timestamp Garmin → POSIXct
      if ("timestamp" %in% names(rec)) {
        rec$timestamp <- FIT_EPOCH + as.numeric(rec$timestamp)
      }

      # Posición: semicírculos → grados (solo si no fue ya convertida)
      if ("position_lat" %in% names(rec))
        rec$position_lat  <- rec$position_lat  * (180 / 2^31)
      if ("position_long" %in% names(rec))
        rec$position_long <- rec$position_long * (180 / 2^31)

      # Fallbacks NA para columnas ausentes
      for (col in c("heart_rate","cadence","speed","altitude","temperature",
                    "distance","position_lat","position_long")) {
        if (!col %in% names(rec)) rec[[col]] <- NA_real_
      }

      rec <- rec %>%
        mutate(
          speed_mps   = as.numeric(speed),
          pace_str    = sapply(speed_mps, mps_to_pace),
          pace_secs   = ifelse(!is.na(speed_mps) & speed_mps > 0,
                               1000 / speed_mps, NA_real_),
          cadence_spm = as.numeric(cadence) * 2,
          altitude_m  = as.numeric(altitude),
          hr_bpm      = as.numeric(heart_rate),
          temp_c      = as.numeric(temperature),
          dist_km     = as.numeric(distance),   # ya en m aplicamos /100 en scale
          lat         = as.numeric(position_lat),
          lon         = as.numeric(position_long)
        ) %>%
        select(timestamp, hr_bpm, cadence_spm, speed_mps, pace_secs, pace_str,
               altitude_m, temp_c, dist_km, lat, lon)

      # ── Construir dataframe de laps ───────────────────────────────────────
      laps <- NULL
      if (length(laps_lst) > 0) {
        all_lap_keys <- unique(unlist(lapply(laps_lst, names)))
        laps_df <- as.data.frame(
          setNames(
            lapply(all_lap_keys, function(k)
              sapply(laps_lst, function(r) if (!is.null(r[[k]])) r[[k]] else NA_real_)
            ),
            all_lap_keys
          ),
          stringsAsFactors = FALSE
        )

        get_col <- function(df, col) {
          if (col %in% names(df)) as.numeric(df[[col]]) else rep(NA_real_, nrow(df))
        }

        laps <- data.frame(
          lap_num     = seq_len(nrow(laps_df)),
          lap_dist_km = get_col(laps_df, "total_distance"),
          lap_time_s  = get_col(laps_df, "total_elapsed_time"),
          lap_hr      = get_col(laps_df, "avg_heart_rate"),
          lap_cadence = get_col(laps_df, "avg_cadence") * 2,
          lap_stride  = get_col(laps_df, "avg_step_length") / 1000,
          stringsAsFactors = FALSE
        ) %>%
          mutate(
            lap_pace_str = ifelse(
              !is.na(lap_dist_km) & lap_dist_km > 0 & !is.na(lap_time_s),
              secs_to_pace_str(lap_time_s / lap_dist_km),
              NA_character_
            )
          ) %>%
          select(lap_num, lap_dist_km, lap_time_s, lap_pace_str,
                 lap_hr, lap_cadence, lap_stride)
      }

      # ── Resumen de sesión ─────────────────────────────────────────────────
      dist_total   <- max(rec$dist_km, na.rm = TRUE)
      tiempo_total <- as.numeric(difftime(max(rec$timestamp, na.rm = TRUE),
                                          min(rec$timestamp, na.rm = TRUE),
                                          units = "secs"))
      fecha        <- as.Date(min(rec$timestamp, na.rm = TRUE))
      pace_medio_s <- if (dist_total > 0) tiempo_total / dist_total else NA_real_

      resumen <- data.frame(
        archivo        = nombre_archivo,
        fecha          = fecha,
        distancia_km   = round(dist_total, 2),
        tiempo_s       = round(tiempo_total),
        tiempo_hms     = seconds_to_hms(tiempo_total),
        ritmo_medio    = secs_to_pace_str(pace_medio_s),
        ritmo_medio_s  = pace_medio_s,
        cadencia_media = round(mean(rec$cadence_spm, na.rm = TRUE)),
        fc_media       = round(mean(rec$hr_bpm, na.rm = TRUE)),
        fc_max         = round(max(rec$hr_bpm, na.rm = TRUE)),
        altitud_max    = round(max(rec$altitude_m, na.rm = TRUE)),
        altitud_min    = round(min(rec$altitude_m, na.rm = TRUE)),
        temp_media     = round(mean(rec$temp_c, na.rm = TRUE), 1),
        n_records      = nrow(rec),
        stringsAsFactors = FALSE
      )

      list(ok = TRUE, resumen = resumen, records = rec, laps = laps)

    }, error = function(e) {
      list(ok = FALSE, error = conditionMessage(e), archivo = nombre_archivo)
    })
  }

  # ────────────────────────────────────────────────────────────────────────────
  # CAPA 1 — fit_data(): parsea todos los archivos cargados
  # Resultado: lista con elementos $resumen, $records, $laps, $errores
  # ────────────────────────────────────────────────────────────────────────────
  fit_data <- reactive({
    req(fit_paths())
    archivos <- fit_paths()

    resultados <- lapply(seq_len(nrow(archivos)), function(i) {
      parse_fit(archivos$datapath[i], archivos$name[i])
    })

    exitosos  <- Filter(function(r) r$ok, resultados)
    fallidos  <- Filter(function(r) !r$ok, resultados)

    if (length(exitosos) == 0) {
      return(list(
        resumen  = NULL,
        records  = list(),
        laps     = list(),
        errores  = fallidos
      ))
    }

    # Consolidar resúmenes en un único dataframe
    resumen_global <- bind_rows(lapply(exitosos, `[[`, "resumen")) %>%
      arrange(fecha)

    # Records y laps como listas nombradas por fecha (string)
    records_lista <- setNames(
      lapply(exitosos, `[[`, "records"),
      sapply(exitosos, function(r) as.character(r$resumen$fecha))
    )
    laps_lista <- setNames(
      lapply(exitosos, `[[`, "laps"),
      sapply(exitosos, function(r) as.character(r$resumen$fecha))
    )

    list(
      resumen = resumen_global,
      records = records_lista,
      laps    = laps_lista,
      errores = fallidos
    )
  })

  # ── Accesores convenientes ────────────────────────────────────────────────
  sesiones <- reactive({
    req(fit_data())
    fit_data()$resumen
  })

  telemetria <- reactive({
    req(fit_data())
    fit_data()$records
  })

  laps <- reactive({
    req(fit_data())
    fit_data()$laps
  })

  # ────────────────────────────────────────────────────────────────────────────
  # Tab 1 — DATA FILE: tabla de sesiones cargadas + errores
  # ────────────────────────────────────────────────────────────────────────────
  output$tabla_sesiones <- renderTable({
    req(sesiones())
    sesiones() %>%
      select(
        Archivo      = archivo,
        Fecha        = fecha,
        `Dist (km)`  = distancia_km,
        Tiempo       = tiempo_hms,
        `Ritmo medio`= ritmo_medio,
        `Cadencia (pmm)` = cadencia_media,
        `FC media`   = fc_media,
        `FC máx`     = fc_max,
        `Temp (°C)`  = temp_media
      )
  }, striped = TRUE, hover = TRUE, bordered = TRUE)

  output$errores_carga <- renderUI({
    req(fit_data())
    errs <- fit_data()$errores
    if (length(errs) == 0) return(NULL)
    msgs <- sapply(errs, function(e) paste0("⚠️ ", e$archivo, ": ", e$error))
    tags$div(class = "alert alert-warning",
             tags$strong("Archivos con error:"),
             tags$ul(lapply(msgs, tags$li)))
  })

  # Contador de sesiones cargadas en el sidebar
  output$n_sesiones <- renderText({
    if (is.null(sesiones())) return("Sin datos")
    paste(nrow(sesiones()), "sesiones cargadas")
  })

  # ────────────────────────────────────────────────────────────────────────────
  # Poblar selectInputs de fecha en todas las tabs
  # ────────────────────────────────────────────────────────────────────────────
  observe({
    req(sesiones())
    fechas <- as.character(sesiones()$fecha)

    updateSelectInput(session, "sel_fecha_sesion",  choices = fechas)
    updateSelectInput(session, "sel_fecha_cardio",  choices = fechas)
    updateSelectInput(session, "sel_fecha_bio",     choices = fechas)
    updateSelectInput(session, "comp_fecha_1",      choices = fechas)
    updateSelectInput(session, "comp_fecha_2",      choices = fechas,
                      selected = if (length(fechas) > 1) fechas[2] else fechas[1])
  })

  # ────────────────────────────────────────────────────────────────────────────
  # Tab 2 — SESIÓN: ficha de solo lectura + gráficos intrasesión
  # ────────────────────────────────────────────────────────────────────────────

  # Datos de la sesión seleccionada
  sesion_sel <- reactive({
    req(sesiones(), input$sel_fecha_sesion)
    sesiones() %>% filter(fecha == as.Date(input$sel_fecha_sesion))
  })

  rec_sel <- reactive({
    req(telemetria(), input$sel_fecha_sesion)
    telemetria()[[input$sel_fecha_sesion]]
  })

  laps_sel <- reactive({
    req(laps(), input$sel_fecha_sesion)
    laps()[[input$sel_fecha_sesion]]
  })

  # Value boxes de la sesión
  output$box_dist    <- renderValueBox(valueBox(
    paste(sesion_sel()$distancia_km, "km"), "Distancia", icon("road"), color = "blue"))
  output$box_tiempo  <- renderValueBox(valueBox(
    sesion_sel()$tiempo_hms, "Tiempo", icon("clock"), color = "navy"))
  output$box_ritmo   <- renderValueBox(valueBox(
    paste(sesion_sel()$ritmo_medio, "/km"), "Ritmo medio", icon("tachometer-alt"), color = "green"))
  output$box_cad     <- renderValueBox(valueBox(
    paste(sesion_sel()$cadencia_media, "pmm"), "Cadencia", icon("shoe-prints"), color = "purple"))
  output$box_fc      <- renderValueBox(valueBox(
    paste(sesion_sel()$fc_media, "bpm"), "FC media", icon("heartbeat"), color = "red"))
  output$box_fc_max  <- renderValueBox(valueBox(
    paste(sesion_sel()$fc_max, "bpm"), "FC máx", icon("heart"), color = "maroon"))

  # Gráfico: FC + ritmo (eje dual) a lo largo de la sesión
  output$plot_sesion_fc_ritmo <- renderPlotly({
    rec <- rec_sel()
    req(nrow(rec) > 0)
    rec <- rec %>% filter(!is.na(dist_km), !is.na(hr_bpm) | !is.na(pace_secs))

    p1 <- plot_ly(rec, x = ~dist_km) %>%
      add_lines(y = ~hr_bpm, name = "FC (bpm)",
                line = list(color = "#e74c3c"), yaxis = "y1") %>%
      add_lines(y = ~pace_secs, name = "Ritmo (s/km)",
                line = list(color = "#2ecc71"), yaxis = "y2") %>%
      layout(
        title  = "FC y Ritmo a lo largo de la sesión",
        xaxis  = list(title = "Distancia (km)"),
        yaxis  = list(title = "FC (bpm)", side = "left"),
        yaxis2 = list(title = "Ritmo (s/km)", side = "right",
                      overlaying = "y", autorange = "reversed"),
        legend = list(orientation = "h")
      )
    p1
  })

  # Gráfico: Cadencia + altitud
  output$plot_sesion_cad_alt <- renderPlotly({
    rec <- rec_sel()
    req(nrow(rec) > 0)

    plot_ly(rec, x = ~dist_km) %>%
      add_lines(y = ~cadence_spm, name = "Cadencia (pmm)",
                line = list(color = "#9b59b6")) %>%
      add_lines(y = ~altitude_m, name = "Altitud (m)",
                line = list(color = "#f39c12"), yaxis = "y2") %>%
      layout(
        title  = "Cadencia y Altitud",
        xaxis  = list(title = "Distancia (km)"),
        yaxis  = list(title = "Cadencia (pmm)"),
        yaxis2 = list(title = "Altitud (m)", side = "right", overlaying = "y"),
        legend = list(orientation = "h")
      )
  })

  # Tabla de laps
  output$tabla_laps <- renderTable({
    req(laps_sel())
    laps_sel() %>%
      rename(
        Lap            = lap_num,
        `Dist (km)`   = lap_dist_km,
        `Tiempo (s)`  = lap_time_s,
        `Ritmo`       = lap_pace_str,
        `FC media`    = lap_hr,
        `Cadencia`    = lap_cadence,
        `Zancada (m)` = lap_stride
      )
  }, striped = TRUE, hover = TRUE, na = "—")

  # ────────────────────────────────────────────────────────────────────────────
  # Tab 3 — EVOLUCIÓN: series temporales longitudinales
  # ────────────────────────────────────────────────────────────────────────────
  output$plot_evol_distancia <- renderPlotly({
    req(sesiones())
    df <- sesiones() %>% arrange(fecha)
    p <- ggplot(df, aes(x = fecha, y = distancia_km,
                        text = paste("Fecha:", fecha, "<br>Dist:", distancia_km, "km"))) +
      geom_line(color = "#1f77b4") + geom_point(color = "#1f77b4", size = 2) +
      geom_smooth(method = "loess", se = TRUE, alpha = 0.15, color = "#aec7e8") +
      labs(title = "Distancia por sesión", x = NULL, y = "km") + theme_minimal()
    ggplotly(p, tooltip = "text")
  })

  output$plot_evol_ritmo <- renderPlotly({
    req(sesiones())
    df <- sesiones() %>% arrange(fecha)
    p <- ggplot(df, aes(x = fecha, y = ritmo_medio_s,
                        text = paste("Fecha:", fecha, "<br>Ritmo:", ritmo_medio, "/km"))) +
      geom_line(color = "#2ca02c") + geom_point(color = "#2ca02c", size = 2) +
      geom_smooth(method = "loess", se = TRUE, alpha = 0.15, color = "#98df8a") +
      scale_y_reverse(labels = function(s) secs_to_pace_str(s)) +
      labs(title = "Ritmo medio por sesión (↓ mejor)", x = NULL, y = "min/km") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })

  output$plot_evol_cadencia <- renderPlotly({
    req(sesiones())
    df <- sesiones() %>% arrange(fecha)
    p <- ggplot(df, aes(x = fecha, y = cadencia_media,
                        text = paste("Fecha:", fecha, "<br>Cadencia:", cadencia_media, "pmm"))) +
      geom_line(color = "#9467bd") + geom_point(color = "#9467bd", size = 2) +
      geom_smooth(method = "loess", se = TRUE, alpha = 0.15, color = "#c5b0d5") +
      labs(title = "Cadencia media por sesión", x = NULL, y = "pmm") + theme_minimal()
    ggplotly(p, tooltip = "text")
  })

  output$plot_evol_fc <- renderPlotly({
    req(sesiones())
    df <- sesiones() %>% arrange(fecha)
    p <- ggplot(df, aes(x = fecha, y = fc_media,
                        text = paste("Fecha:", fecha, "<br>FC:", fc_media, "bpm"))) +
      geom_line(color = "#d62728") + geom_point(color = "#d62728", size = 2) +
      geom_smooth(method = "loess", se = TRUE, alpha = 0.15, color = "#f7b6d2") +
      labs(title = "FC media por sesión", x = NULL, y = "bpm") + theme_minimal()
    ggplotly(p, tooltip = "text")
  })

  # Eficiencia aeróbica: ritmo (s/km) / FC — baja = más eficiente
  output$plot_evol_eficiencia <- renderPlotly({
    req(sesiones())
    df <- sesiones() %>%
      arrange(fecha) %>%
      mutate(eficiencia = ritmo_medio_s / fc_media)
    p <- ggplot(df, aes(x = fecha, y = eficiencia,
                        text = paste("Fecha:", fecha,
                                     "<br>Eficiencia:", round(eficiencia, 2)))) +
      geom_line(color = "#ff7f0e") + geom_point(color = "#ff7f0e", size = 2) +
      geom_smooth(method = "loess", se = TRUE, alpha = 0.15, color = "#ffbb78") +
      scale_y_reverse() +
      labs(title = "Eficiencia aeróbica (ritmo/FC) — ↓ mejor", x = NULL, y = "s·km⁻¹·bpm⁻¹") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })

  # ────────────────────────────────────────────────────────────────────────────
  # Tab 4 — COMPARAR: dos sesiones normalizadas
  # ────────────────────────────────────────────────────────────────────────────
  output$tabla_comp_1 <- renderTable({
    req(sesiones(), input$comp_fecha_1)
    sesiones() %>%
      filter(fecha == as.Date(input$comp_fecha_1)) %>%
      select(Fecha=fecha, `Dist (km)`=distancia_km, Tiempo=tiempo_hms,
             Ritmo=ritmo_medio, `Cadencia (pmm)`=cadencia_media,
             `FC media`=fc_media, `FC máx`=fc_max)
  }, striped = TRUE)

  output$tabla_comp_2 <- renderTable({
    req(sesiones(), input$comp_fecha_2)
    sesiones() %>%
      filter(fecha == as.Date(input$comp_fecha_2)) %>%
      select(Fecha=fecha, `Dist (km)`=distancia_km, Tiempo=tiempo_hms,
             Ritmo=ritmo_medio, `Cadencia (pmm)`=cadencia_media,
             `FC media`=fc_media, `FC máx`=fc_max)
  }, striped = TRUE)

  output$plot_comparacion <- renderPlotly({
    req(sesiones(), input$comp_fecha_1, input$comp_fecha_2)
    df <- sesiones()
    r1 <- df %>% filter(fecha == as.Date(input$comp_fecha_1))
    r2 <- df %>% filter(fecha == as.Date(input$comp_fecha_2))
    if (nrow(r1) == 0 || nrow(r2) == 0) return(NULL)

    # Normalizar cada métrica a % del máximo entre las dos sesiones
    vars <- list(
      list(nombre="Dist (km)",       v1=r1$distancia_km,   v2=r2$distancia_km),
      list(nombre="FC media (bpm)",  v1=r1$fc_media,       v2=r2$fc_media),
      list(nombre="Cadencia (pmm)",  v1=r1$cadencia_media, v2=r2$cadencia_media),
      list(nombre="Ritmo (s/km)↓",  v1=r1$ritmo_medio_s,  v2=r2$ritmo_medio_s)
    )

    comp_df <- bind_rows(lapply(vars, function(v) {
      mx <- max(v$v1, v$v2, na.rm = TRUE)
      data.frame(
        Metrica    = v$nombre,
        Sesion     = c(as.character(r1$fecha), as.character(r2$fecha)),
        Valor_norm = c(v$v1/mx*100, v$v2/mx*100),
        Valor_real = c(v$v1, v$v2)
      )
    }))

    p <- ggplot(comp_df, aes(x = Metrica, y = Valor_norm, fill = Sesion,
                              text = paste("Sesión:", Sesion,
                                           "<br>Valor real:", round(Valor_real, 2)))) +
      geom_bar(stat = "identity", position = "dodge") +
      scale_fill_manual(values = c("#1f77b4", "#ff7f0e")) +
      labs(title = "Comparación normalizada (% del máximo)",
           x = NULL, y = "% del máximo entre las dos sesiones") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })

  # Comparación de telemetría superpuesta (FC vs distancia)
  output$plot_comp_telemetria <- renderPlotly({
    req(telemetria(), input$comp_fecha_1, input$comp_fecha_2)
    r1 <- telemetria()[[input$comp_fecha_1]]
    r2 <- telemetria()[[input$comp_fecha_2]]
    if (is.null(r1) || is.null(r2)) return(NULL)

    plot_ly() %>%
      add_lines(data = r1, x = ~dist_km, y = ~hr_bpm,
                name = input$comp_fecha_1, line = list(color = "#1f77b4")) %>%
      add_lines(data = r2, x = ~dist_km, y = ~hr_bpm,
                name = input$comp_fecha_2, line = list(color = "#ff7f0e")) %>%
      layout(title = "FC vs distancia — comparación de sesiones",
             xaxis = list(title = "Distancia (km)"),
             yaxis = list(title = "FC (bpm)"),
             legend = list(orientation = "h"))
  })

  # ────────────────────────────────────────────────────────────────────────────
  # Tab 5 — FISIOLOGÍA: zonas FC, deriva cardiaca, carga acumulada
  # ────────────────────────────────────────────────────────────────────────────

  # Zonas FC basadas en FC máxima histórica (configurable)
  zonas_fc <- reactive({
    req(sesiones())
    fc_max_hist <- max(sesiones()$fc_max, na.rm = TRUE)
    list(
      z1 = c(0,             fc_max_hist * 0.60),
      z2 = c(fc_max_hist * 0.60, fc_max_hist * 0.70),
      z3 = c(fc_max_hist * 0.70, fc_max_hist * 0.80),
      z4 = c(fc_max_hist * 0.80, fc_max_hist * 0.90),
      z5 = c(fc_max_hist * 0.90, fc_max_hist)
    )
  })

  output$plot_zonas_fc <- renderPlotly({
    req(rec_sel(), zonas_fc())
    rec <- rec_sel() %>% filter(!is.na(hr_bpm))
    z   <- zonas_fc()

    rec <- rec %>%
      mutate(zona = case_when(
        hr_bpm < z$z2[1]  ~ "Z1 Recuperación",
        hr_bpm < z$z3[1]  ~ "Z2 Base aeróbica",
        hr_bpm < z$z4[1]  ~ "Z3 Tempo",
        hr_bpm < z$z5[1]  ~ "Z4 Umbral",
        TRUE               ~ "Z5 VO2max"
      ))

    dist_zona <- rec %>%
      group_by(zona) %>%
      summarise(dist = max(dist_km, na.rm=TRUE) - min(dist_km, na.rm=TRUE), .groups="drop")

    p <- ggplot(dist_zona, aes(x = zona, y = dist, fill = zona)) +
      geom_bar(stat = "identity") +
      scale_fill_manual(values = c(
        "Z1 Recuperación" = "#3498db",
        "Z2 Base aeróbica"= "#2ecc71",
        "Z3 Tempo"        = "#f1c40f",
        "Z4 Umbral"       = "#e67e22",
        "Z5 VO2max"       = "#e74c3c"
      )) +
      labs(title = "Distribución por zonas de FC", x = NULL, y = "km") +
      theme_minimal() + theme(legend.position = "none")
    ggplotly(p)
  })

  # Deriva cardiaca: FC vs distancia con línea de tendencia
  output$plot_deriva_fc <- renderPlotly({
    req(rec_sel())
    rec <- rec_sel() %>% filter(!is.na(hr_bpm), !is.na(dist_km))
    p <- ggplot(rec, aes(x = dist_km, y = hr_bpm)) +
      geom_line(color = "#e74c3c", alpha = 0.5) +
      geom_smooth(method = "lm", color = "#c0392b", se = FALSE) +
      labs(title = "Deriva cardiaca (pendiente = fatiga acumulada)",
           x = "Distancia (km)", y = "FC (bpm)") +
      theme_minimal()
    ggplotly(p)
  })

  # Carga acumulada semanal (dist × FC_media normalizada)
  output$plot_carga_semanal <- renderPlotly({
    req(sesiones())
    df <- sesiones() %>%
      mutate(
        semana  = floor_date(fecha, "week"),
        fc_norm = fc_media / max(fc_max, na.rm = TRUE),
        carga   = distancia_km * fc_norm
      ) %>%
      group_by(semana) %>%
      summarise(carga_semana = sum(carga, na.rm = TRUE), .groups = "drop")

    p <- ggplot(df, aes(x = semana, y = carga_semana,
                         text = paste("Semana:", semana, "<br>Carga:", round(carga_semana,1)))) +
      geom_col(fill = "#e67e22") +
      labs(title = "Carga de entrenamiento semanal (dist × FC normalizada)",
           x = NULL, y = "Unidades de carga") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })

  # ────────────────────────────────────────────────────────────────────────────
  # Tab 6 — BIOMECÁNICA: cadencia vs zancada, degradación intrasesión, laps
  # ────────────────────────────────────────────────────────────────────────────

  # Longitud de zancada derivada: v (m/s) / (cadencia/60)
  output$plot_bio_zancada <- renderPlotly({
    req(rec_sel())
    rec <- rec_sel() %>%
      filter(!is.na(cadence_spm), cadence_spm > 0, !is.na(speed_mps)) %>%
      mutate(stride_m = (speed_mps / (cadence_spm / 60)) )

    plot_ly(rec, x = ~dist_km) %>%
      add_lines(y = ~cadence_spm, name = "Cadencia (pmm)",
                line = list(color = "#9b59b6")) %>%
      add_lines(y = ~stride_m * 100, name = "Zancada ×100 (cm)",
                line = list(color = "#27ae60"), yaxis = "y2") %>%
      layout(
        title  = "Cadencia vs Longitud de zancada",
        xaxis  = list(title = "Distancia (km)"),
        yaxis  = list(title = "Cadencia (pmm)"),
        yaxis2 = list(title = "Zancada (cm)", side = "right", overlaying = "y"),
        legend = list(orientation = "h")
      )
  })

  # ¿Qué domina el ritmo? Scatter cadencia vs velocidad coloreado por zona
  output$plot_bio_scatter <- renderPlotly({
    req(rec_sel(), zonas_fc())
    rec <- rec_sel() %>%
      filter(!is.na(cadence_spm), !is.na(speed_mps), !is.na(hr_bpm)) %>%
      mutate(
        velocidad_kmh = speed_mps * 3.6,
        zona = case_when(
          hr_bpm < zonas_fc()$z2[1] ~ "Z1",
          hr_bpm < zonas_fc()$z3[1] ~ "Z2",
          hr_bpm < zonas_fc()$z4[1] ~ "Z3",
          hr_bpm < zonas_fc()$z5[1] ~ "Z4",
          TRUE ~ "Z5"
        )
      )

    p <- ggplot(rec, aes(x = cadence_spm, y = velocidad_kmh, color = zona,
                          text = paste("Cadencia:", cadence_spm, "pmm",
                                       "<br>Velocidad:", round(velocidad_kmh,1), "km/h",
                                       "<br>FC:", hr_bpm, "bpm"))) +
      geom_point(alpha = 0.4, size = 1) +
      scale_color_manual(values = c(Z1="#3498db",Z2="#2ecc71",Z3="#f1c40f",Z4="#e67e22",Z5="#e74c3c")) +
      labs(title = "Cadencia vs Velocidad (color = zona FC)",
           x = "Cadencia (pmm)", y = "Velocidad (km/h)") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })

  # Degradación de cadencia por mitades de sesión
  output$plot_bio_degradacion <- renderPlotly({
    req(rec_sel())
    rec <- rec_sel() %>% filter(!is.na(cadence_spm), !is.na(dist_km))
    mid <- max(rec$dist_km, na.rm = TRUE) / 2
    rec <- rec %>%
      mutate(mitad = ifelse(dist_km <= mid, "Primera mitad", "Segunda mitad"))

    p <- ggplot(rec, aes(x = dist_km, y = cadence_spm, color = mitad)) +
      geom_line(alpha = 0.6) +
      geom_smooth(method = "loess", se = FALSE) +
      scale_color_manual(values = c("Primera mitad" = "#2ecc71", "Segunda mitad" = "#e74c3c")) +
      labs(title = "Degradación de cadencia a lo largo de la sesión",
           x = "Distancia (km)", y = "Cadencia (pmm)") +
      theme_minimal()
    ggplotly(p)
  })

  # Análisis de laps: ritmo por lap
  output$plot_bio_laps <- renderPlotly({
    req(laps_sel())
    laps_df <- laps_sel() %>% filter(!is.na(lap_pace_str))
    laps_df <- laps_df %>%
      mutate(pace_secs = sapply(lap_pace_str, pace_str_to_secs))

    p <- ggplot(laps_df, aes(x = lap_num, y = pace_secs,
                              text = paste("Lap:", lap_num,
                                           "<br>Ritmo:", lap_pace_str,
                                           "<br>FC:", lap_hr))) +
      geom_line(color = "#1f77b4") + geom_point(color = "#1f77b4", size = 3) +
      scale_y_reverse(labels = function(s) secs_to_pace_str(s)) +
      labs(title = "Ritmo por lap (↓ más rápido)",
           x = "Lap (km)", y = "Ritmo (min/km)") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })

})
