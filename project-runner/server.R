# ══════════════════════════════════════════════════════════════════════════════
# server.R — Running Biomechanics Dashboard
# ORDEN: helpers y parsers globales primero, shinyServer al final
# ══════════════════════════════════════════════════════════════════════════════

library(shiny)
library(shinydashboard)
library(dplyr)
library(tidyr)
library(ggplot2)
library(plotly)
library(lubridate)

# ══════════════════════════════════════════════════════════════════════════════
# SECCION 1 — HELPERS GLOBALES (disponibles antes del shinyServer)
# ══════════════════════════════════════════════════════════════════════════════

mps_to_pace <- function(mps) {
  if (is.na(mps) || mps == 0) return(NA_character_)
  secs_per_km <- 1000 / mps
  sprintf("%d:%02d", as.integer(secs_per_km %/% 60), as.integer(secs_per_km %% 60))
}

seconds_to_hms <- function(sec) {
  if (is.na(sec)) return(NA_character_)
  sec <- as.integer(sec)
  sprintf("%02d:%02d:%02d", sec %/% 3600, (sec %% 3600) %/% 60, sec %% 60)
}

secs_to_pace_str <- function(sec) {
  if (is.na(sec) || sec <= 0) return(NA_character_)
  sprintf("%d:%02d", as.integer(sec %/% 60), as.integer(sec %% 60))
}

pace_str_to_secs <- function(pace_str) {
  if (is.na(pace_str) || pace_str == "") return(NA_real_)
  pace_str <- gsub(",", ":", as.character(pace_str))
  parts <- strsplit(pace_str, ":")[[1]]
  if (length(parts) < 2) return(NA_real_)
  as.numeric(parts[1]) * 60 + as.numeric(parts[2])
}

tiempo_str_to_secs <- function(t) {
  if (is.na(t) || t == "") return(NA_real_)
  parts <- as.numeric(strsplit(as.character(t), ":")[[1]])
  if (length(parts) == 3) parts[1]*3600 + parts[2]*60 + parts[3]
  else if (length(parts) == 2) parts[1]*60 + parts[2]
  else NA_real_
}

# ══════════════════════════════════════════════════════════════════════════════
# SECCION 2 — PARSER NATIVO .fit (R puro, sin dependencias externas)
# ══════════════════════════════════════════════════════════════════════════════

FIT_EPOCH <- as.POSIXct("1989-12-31 00:00:00", tz = "UTC")

# Tipos base FIT: tamano en bytes
fit_type_size <- c(
  `0` = 1L, `1` = 1L, `2` = 1L, `131` = 2L, `132` = 2L,
  `133` = 4L, `134` = 4L, `7`  = 1L, `136` = 4L, `137` = 8L,
  `10` = 1L, `139` = 2L, `140` = 4L, `13`  = 1L,
  `142` = 8L, `143` = 8L, `144` = 8L
)

# Definiciones de campos para record (mesg 20) y lap (mesg 19)
# scale: divisor; offset: resta tras dividir
fit_fields <- list(
  `20` = list(
    `253` = list(name="timestamp",     scale=1,    offset=0),
    `0`   = list(name="position_lat",  scale=1,    offset=0),
    `1`   = list(name="position_long", scale=1,    offset=0),
    `2`   = list(name="altitude",      scale=5,    offset=500),
    `3`   = list(name="heart_rate",    scale=1,    offset=0),
    `4`   = list(name="cadence",       scale=1,    offset=0),
    `5`   = list(name="distance",      scale=100,  offset=0),
    `6`   = list(name="speed",         scale=1000, offset=0),
    `13`  = list(name="temperature",   scale=1,    offset=0)
  ),
  `19` = list(
    `253` = list(name="timestamp",          scale=1,    offset=0),
    `7`   = list(name="total_elapsed_time", scale=1000, offset=0),
    `9`   = list(name="total_distance",     scale=100,  offset=0),
    `15`  = list(name="avg_heart_rate",     scale=1,    offset=0),
    `16`  = list(name="max_heart_rate",     scale=1,    offset=0),
    `18`  = list(name="avg_cadence",        scale=1,    offset=0),
    `20`  = list(name="avg_speed",          scale=1000, offset=0),
    `40`  = list(name="avg_step_length",    scale=10,   offset=0)
  )
)

read_u8  <- function(con) readBin(con, "integer", n=1, size=1, signed=FALSE, endian="little")
read_u16 <- function(con, e="little") readBin(con, "integer", n=1, size=2, signed=FALSE, endian=e)
read_s32 <- function(con, e="little") readBin(con, "integer", n=1, size=4, signed=TRUE,  endian=e)

read_field_val <- function(con, type_id, size, endian) {
  type_id <- bitwAnd(type_id, 0x9F)  # mask endian bit
  if (type_id %in% c(133L, 134L)) {
    # sint32 / uint32 — leer raw para evitar warning de R con unsigned 32
    raw4 <- readBin(con, "raw", n=4)
    if (type_id == 134L) {
      return(sum(as.numeric(as.integer(raw4)) * 256^(0:3)))
    } else {
      return(readBin(raw4, "integer", n=1, size=4, signed=TRUE, endian=endian))
    }
  }
  if (type_id %in% c(131L, 132L)) {
    return(readBin(con, "integer", n=1, size=2, signed=(type_id==131L), endian=endian))
  }
  if (type_id %in% c(1L, 2L, 0L, 10L, 13L)) {
    return(readBin(con, "integer", n=1, size=1, signed=(type_id==1L), endian="little"))
  }
  # tipos de 8 bytes u otros: leer y descartar
  readBin(con, "raw", n=size)
  return(NA_real_)
}

parse_fit <- function(path, nombre_archivo) {
  tryCatch({
    con <- file(path, "rb")
    on.exit(close(con))

    # Cabecera: leer byte a byte para evitar warnings de R con uint32
    header_size <- read_u8(con)
    protocol    <- read_u8(con)
    prof_lo     <- read_u8(con)
    prof_hi     <- read_u8(con)
    raw4        <- readBin(con, "raw", n=4)
    data_size   <- sum(as.numeric(as.integer(raw4)) * 256^(0:3))
    magic       <- rawToChar(readBin(con, "raw", n=4))
    if (magic != ".FIT") stop("No es un archivo .fit valido (magic='", magic, "')")
    extra <- as.integer(header_size) - 12L
    if (extra > 0) readBin(con, "raw", n=extra)

    local_defs  <- list()
    records_lst <- list()
    laps_lst    <- list()
    bytes_read  <- 0L

    while (bytes_read < data_size) {
      hdr <- read_u8(con)
      if (length(hdr) == 0 || is.na(hdr)) break
      bytes_read <- bytes_read + 1L

      is_compressed <- bitwAnd(hdr, 0x80L) != 0L

      if (is_compressed) {
        local_num <- bitwAnd(bitwShiftR(hdr, 5L), 0x03L)
        def <- local_defs[[as.character(local_num)]]
        if (!is.null(def)) {
          row_size <- sum(sapply(def$fields, function(f) f$size))
          if (row_size > 0) readBin(con, "raw", n=row_size)
          bytes_read <- bytes_read + row_size
        }
        next
      }

      is_def    <- bitwAnd(hdr, 0x40L) != 0L
      has_dev   <- bitwAnd(hdr, 0x20L) != 0L
      local_num <- bitwAnd(hdr, 0x0FL)

      if (is_def) {
        readBin(con, "raw", n=1)          # reserved
        arch     <- read_u8(con)
        endian   <- if (arch == 1L) "big" else "little"
        mesg_num <- read_u16(con, endian)
        n_fields <- read_u8(con)
        bytes_read <- bytes_read + 5L

        fields <- vector("list", n_fields)
        for (i in seq_len(n_fields)) {
          fnum  <- read_u8(con)
          fsize <- read_u8(con)
          ftype <- read_u8(con)
          bytes_read <- bytes_read + 3L
          fields[[i]] <- list(num=fnum, size=fsize, type=ftype)
        }

        if (has_dev) {
          n_dev <- read_u8(con); bytes_read <- bytes_read + 1L
          for (i in seq_len(n_dev)) {
            readBin(con, "raw", n=3); bytes_read <- bytes_read + 3L
          }
        }

        local_defs[[as.character(local_num)]] <- list(
          mesg_num = mesg_num, endian = endian, fields = fields
        )

      } else {
        def <- local_defs[[as.character(local_num)]]
        if (is.null(def)) next

        mesg_key <- as.character(def$mesg_num)
        row <- list()

        for (f in def$fields) {
          val        <- read_field_val(con, f$type, f$size, def$endian)
          bytes_read <- bytes_read + f$size

          fdef <- fit_fields[[mesg_key]][[as.character(f$num)]]
          if (!is.null(fdef) && !is.null(val) && length(val) > 0 && !is.na(val)) {
            row[[fdef$name]] <- (as.numeric(val) / fdef$scale) - fdef$offset
          }
        }

        if (def$mesg_num == 20L && length(row) > 0)
          records_lst[[length(records_lst)+1L]] <- row
        else if (def$mesg_num == 19L && length(row) > 0)
          laps_lst[[length(laps_lst)+1L]] <- row
      }
    }

    if (length(records_lst) == 0)
      stop("No se encontraron records en el archivo .fit")

    # Construir dataframe de records
    all_keys <- unique(unlist(lapply(records_lst, names)))
    rec <- as.data.frame(setNames(
      lapply(all_keys, function(k)
        sapply(records_lst, function(r) if (!is.null(r[[k]])) r[[k]] else NA_real_)
      ), all_keys
    ), stringsAsFactors = FALSE)

    if ("timestamp" %in% names(rec))
      rec$timestamp <- FIT_EPOCH + as.numeric(rec$timestamp)
    if ("position_lat"  %in% names(rec))
      rec$position_lat  <- rec$position_lat  * (180 / 2^31)
    if ("position_long" %in% names(rec))
      rec$position_long <- rec$position_long * (180 / 2^31)

    for (col in c("heart_rate","cadence","speed","altitude",
                  "temperature","distance","position_lat","position_long"))
      if (!col %in% names(rec)) rec[[col]] <- NA_real_

    rec <- rec %>% mutate(
      speed_mps   = as.numeric(speed),
      pace_str    = sapply(speed_mps, mps_to_pace),
      pace_secs   = ifelse(!is.na(speed_mps) & speed_mps > 0, 1000/speed_mps, NA_real_),
      cadence_spm = as.numeric(cadence) * 2,
      altitude_m  = as.numeric(altitude),
      hr_bpm      = as.numeric(heart_rate),
      temp_c      = as.numeric(temperature),
      dist_km     = as.numeric(distance) / 1000,
      lat         = as.numeric(position_lat),
      lon         = as.numeric(position_long)
    ) %>% select(timestamp, hr_bpm, cadence_spm, speed_mps, pace_secs,
                 pace_str, altitude_m, temp_c, dist_km, lat, lon)

    # Construir dataframe de laps
    laps <- NULL
    if (length(laps_lst) > 0) {
      lk <- unique(unlist(lapply(laps_lst, names)))
      laps_df <- as.data.frame(setNames(
        lapply(lk, function(k)
          sapply(laps_lst, function(r) if (!is.null(r[[k]])) r[[k]] else NA_real_)
        ), lk
      ), stringsAsFactors = FALSE)

      gc <- function(col) if (col %in% names(laps_df)) as.numeric(laps_df[[col]]) else rep(NA_real_, nrow(laps_df))
      laps <- data.frame(
        lap_num     = seq_len(nrow(laps_df)),
        lap_dist_km = gc("total_distance"),
        lap_time_s  = gc("total_elapsed_time"),
        lap_hr      = gc("avg_heart_rate"),
        lap_cadence = gc("avg_cadence") * 2,
        lap_stride  = gc("avg_step_length") / 1000,
        stringsAsFactors = FALSE
      ) %>% mutate(
        lap_pace_str = ifelse(!is.na(lap_dist_km) & lap_dist_km > 0 & !is.na(lap_time_s),
                              secs_to_pace_str(lap_time_s / lap_dist_km), NA_character_)
      ) %>% select(lap_num, lap_dist_km, lap_time_s, lap_pace_str, lap_hr, lap_cadence, lap_stride)
    }

    # Resumen
    dist_total   <- max(rec$dist_km, na.rm=TRUE)
    tiempo_total <- as.numeric(difftime(max(rec$timestamp, na.rm=TRUE),
                                        min(rec$timestamp, na.rm=TRUE), units="secs"))
    fecha        <- as.Date(min(rec$timestamp, na.rm=TRUE))
    pace_s       <- if (!is.na(dist_total) && dist_total > 0) tiempo_total/dist_total else NA_real_

    resumen <- data.frame(
      archivo        = nombre_archivo,
      fecha          = fecha,
      distancia_km   = round(dist_total, 2),
      tiempo_s       = round(tiempo_total),
      tiempo_hms     = seconds_to_hms(tiempo_total),
      ritmo_medio    = secs_to_pace_str(pace_s),
      ritmo_medio_s  = pace_s,
      cadencia_media = round(mean(rec$cadence_spm, na.rm=TRUE)),
      fc_media       = round(mean(rec$hr_bpm, na.rm=TRUE)),
      fc_max         = round(max(rec$hr_bpm, na.rm=TRUE)),
      altitud_max    = round(max(rec$altitude_m, na.rm=TRUE)),
      altitud_min    = round(min(rec$altitude_m, na.rm=TRUE)),
      temp_media     = round(mean(rec$temp_c, na.rm=TRUE), 1),
      n_records      = nrow(rec),
      formato        = "fit",
      stringsAsFactors = FALSE
    )

    list(ok=TRUE, resumen=resumen, records=rec, laps=laps)

  }, error = function(e) {
    list(ok=FALSE, error=conditionMessage(e), archivo=nombre_archivo)
  })
}

# ══════════════════════════════════════════════════════════════════════════════
# SECCION 3 — PARSER CSV (Garmin Connect export)
# ══════════════════════════════════════════════════════════════════════════════

parse_csv <- function(path, nombre_archivo) {
  tryCatch({
    df <- read.csv(path, stringsAsFactors=FALSE, check.names=FALSE, encoding="UTF-8")

    norm <- function(x) {
      x <- tolower(x)
      x <- chartr("\u00e1\u00e9\u00ed\u00f3\u00fa", "aeiou", x)
      x <- gsub("[^a-z0-9]", "_", x)
      gsub("_+", "_", trimws(x, whitespace="_"))
    }
    names(df) <- norm(names(df))

    col_map <- list(
      fecha          = c("fecha","date"),
      distancia_km   = c("distancia","distance","distancia_km"),
      tiempo_hms     = c("tiempo","time","duracion"),
      ritmo_medio    = c("ritmo_medio","avg_pace","ritmo_medio_min_km","pace"),
      cadencia_media = c("cadencia_de_carrera_media","avg_run_cadence","cadencia_media","cadencia"),
      fc_media       = c("frecuencia_cardiaca_media","avg_hr","fc_media","frecuencia_cardiaca"),
      fc_max         = c("frecuencia_cardiaca_maxima","max_hr","fc_max"),
      altitud_max    = c("altitud_maxima","max_elev","altitud_max"),
      altitud_min    = c("altitud_minima","min_elev","altitud_min"),
      temp_media     = c("temperatura_media","avg_temp","temperatura")
    )

    gc <- function(candidates) {
      hit <- intersect(candidates, names(df))
      if (length(hit) > 0) df[[hit[1]]] else rep(NA, nrow(df))
    }

    fecha_raw  <- gc(col_map$fecha)
    fecha_p    <- suppressWarnings(as.Date(fecha_raw,
                    tryFormats=c("%Y-%m-%d","%d/%m/%Y","%m/%d/%Y","%d-%m-%Y")))
    dist_num   <- suppressWarnings(as.numeric(gsub(",",".", as.character(gc(col_map$distancia_km)))))
    tiempo_raw <- as.character(gc(col_map$tiempo_hms))
    ritmo_raw  <- as.character(gc(col_map$ritmo_medio))
    ritmo_s    <- sapply(ritmo_raw, pace_str_to_secs)
    tiempo_s   <- sapply(tiempo_raw, tiempo_str_to_secs)

    resumen <- data.frame(
      archivo        = nombre_archivo,
      fecha          = fecha_p,
      distancia_km   = round(dist_num, 2),
      tiempo_s       = round(tiempo_s),
      tiempo_hms     = tiempo_raw,
      ritmo_medio    = ritmo_raw,
      ritmo_medio_s  = ritmo_s,
      cadencia_media = round(suppressWarnings(as.numeric(gc(col_map$cadencia_media)))),
      fc_media       = round(suppressWarnings(as.numeric(gc(col_map$fc_media)))),
      fc_max         = round(suppressWarnings(as.numeric(gc(col_map$fc_max)))),
      altitud_max    = round(suppressWarnings(as.numeric(gc(col_map$altitud_max)))),
      altitud_min    = round(suppressWarnings(as.numeric(gc(col_map$altitud_min)))),
      temp_media     = round(suppressWarnings(as.numeric(gc(col_map$temp_media))), 1),
      n_records      = NA_integer_,
      formato        = "csv",
      stringsAsFactors = FALSE
    ) %>% filter(!is.na(fecha))

    if (nrow(resumen) == 0) stop("No se encontraron filas con fecha valida")

    list(ok=TRUE, resumen=resumen, records=NULL, laps=NULL)

  }, error = function(e) {
    list(ok=FALSE, error=conditionMessage(e), archivo=nombre_archivo)
  })
}

# ══════════════════════════════════════════════════════════════════════════════
# SECCION 4 — SHINY SERVER
# ══════════════════════════════════════════════════════════════════════════════

shinyServer(function(input, output, session) {

  # ── Capa reactiva: combina FIT + CSV ───────────────────────────────────────
  todos_los_datos <- reactive({
    tiene_fit <- !is.null(input$fit_files)
    tiene_csv <- !is.null(input$csv_files)
    if (!tiene_fit && !tiene_csv) return(NULL)

    resultados <- list()
    if (tiene_fit) {
      af <- input$fit_files
      resultados <- c(resultados,
        lapply(seq_len(nrow(af)), function(i) parse_fit(af$datapath[i], af$name[i])))
    }
    if (tiene_csv) {
      ac <- input$csv_files
      resultados <- c(resultados,
        lapply(seq_len(nrow(ac)), function(i) parse_csv(ac$datapath[i], ac$name[i])))
    }

    exitosos <- Filter(function(r) r$ok,  resultados)
    fallidos <- Filter(function(r) !r$ok, resultados)

    if (length(exitosos) == 0)
      return(list(resumen=NULL, records=list(), laps=list(), errores=fallidos))

    resumen_global <- bind_rows(lapply(exitosos, `[[`, "resumen")) %>% arrange(fecha)

    mk_named <- function(key) setNames(
      lapply(exitosos, `[[`, key),
      sapply(exitosos, function(r) as.character(r$resumen$fecha[1]))
    )

    list(resumen=resumen_global, records=mk_named("records"),
         laps=mk_named("laps"), errores=fallidos)
  })

  sesiones   <- reactive({ req(todos_los_datos()); todos_los_datos()$resumen  })
  telemetria <- reactive({ req(todos_los_datos()); todos_los_datos()$records  })
  laps_data  <- reactive({ req(todos_los_datos()); todos_los_datos()$laps     })

  # ── Tab 1: Datos ────────────────────────────────────────────────────────────
  output$tabla_sesiones <- renderTable({
    req(sesiones())
    sesiones() %>% select(
      Formato        = formato,
      Archivo        = archivo,
      Fecha          = fecha,
      `Dist (km)`    = distancia_km,
      Tiempo         = tiempo_hms,
      `Ritmo medio`  = ritmo_medio,
      `Cadencia (pmm)` = cadencia_media,
      `FC media`     = fc_media,
      `FC max`       = fc_max,
      `Temp (C)`     = temp_media
    )
  }, striped=TRUE, hover=TRUE, bordered=TRUE)

  output$errores_carga <- renderUI({
    req(todos_los_datos())
    errs <- todos_los_datos()$errores
    if (length(errs) == 0) return(NULL)
    msgs <- sapply(errs, function(e) paste0("Archivo: ", e$archivo, " — ", e$error))
    tags$div(class="alert alert-warning",
             tags$strong("Archivos con error:"),
             tags$ul(lapply(msgs, tags$li)))
  })

  output$n_sesiones <- renderText({
    if (is.null(sesiones())) return("Sin datos")
    paste(nrow(sesiones()), "sesiones cargadas")
  })

  # ── Poblar selectInputs en todas las tabs ───────────────────────────────────
  observe({
    req(sesiones())
    fechas <- as.character(sesiones()$fecha)
    updateSelectInput(session, "sel_fecha_sesion", choices=fechas)
    updateSelectInput(session, "sel_fecha_cardio", choices=fechas)
    updateSelectInput(session, "sel_fecha_bio",    choices=fechas)
    updateSelectInput(session, "comp_fecha_1",     choices=fechas)
    updateSelectInput(session, "comp_fecha_2",     choices=fechas,
                      selected=if(length(fechas)>1) fechas[2] else fechas[1])
  })

  # ── Tab 2: Sesion ───────────────────────────────────────────────────────────
  sesion_sel <- reactive({
    req(sesiones(), input$sel_fecha_sesion)
    sesiones() %>% filter(fecha == as.Date(input$sel_fecha_sesion))
  })
  rec_sel <- reactive({
    req(telemetria(), input$sel_fecha_sesion)
    telemetria()[[input$sel_fecha_sesion]]
  })
  laps_sel <- reactive({
    req(laps_data(), input$sel_fecha_sesion)
    laps_data()[[input$sel_fecha_sesion]]
  })

  output$box_dist   <- renderValueBox(valueBox(
    paste(sesion_sel()$distancia_km, "km"), "Distancia", icon("road"), color="blue"))
  output$box_tiempo <- renderValueBox(valueBox(
    sesion_sel()$tiempo_hms, "Tiempo", icon("clock"), color="navy"))
  output$box_ritmo  <- renderValueBox(valueBox(
    paste(sesion_sel()$ritmo_medio, "/km"), "Ritmo medio", icon("tachometer-alt"), color="green"))
  output$box_cad    <- renderValueBox(valueBox(
    paste(sesion_sel()$cadencia_media, "pmm"), "Cadencia", icon("shoe-prints"), color="purple"))
  output$box_fc     <- renderValueBox(valueBox(
    paste(sesion_sel()$fc_media, "bpm"), "FC media", icon("heartbeat"), color="red"))
  output$box_fc_max <- renderValueBox(valueBox(
    paste(sesion_sel()$fc_max, "bpm"), "FC max", icon("heart"), color="maroon"))

  output$plot_sesion_fc_ritmo <- renderPlotly({
    rec <- rec_sel(); req(!is.null(rec), nrow(rec) > 0)
    plot_ly(rec, x=~dist_km) %>%
      add_lines(y=~hr_bpm,    name="FC (bpm)",    line=list(color="#e74c3c"), yaxis="y1") %>%
      add_lines(y=~pace_secs, name="Ritmo (s/km)",line=list(color="#2ecc71"), yaxis="y2") %>%
      layout(title="FC y Ritmo a lo largo de la sesion",
             xaxis=list(title="Distancia (km)"),
             yaxis=list(title="FC (bpm)", side="left"),
             yaxis2=list(title="Ritmo (s/km)", side="right",
                         overlaying="y", autorange="reversed"),
             legend=list(orientation="h"))
  })

  output$plot_sesion_cad_alt <- renderPlotly({
    rec <- rec_sel(); req(!is.null(rec), nrow(rec) > 0)
    plot_ly(rec, x=~dist_km) %>%
      add_lines(y=~cadence_spm, name="Cadencia (pmm)", line=list(color="#9b59b6")) %>%
      add_lines(y=~altitude_m,  name="Altitud (m)",    line=list(color="#f39c12"), yaxis="y2") %>%
      layout(title="Cadencia y Altitud",
             xaxis=list(title="Distancia (km)"),
             yaxis=list(title="Cadencia (pmm)"),
             yaxis2=list(title="Altitud (m)", side="right", overlaying="y"),
             legend=list(orientation="h"))
  })

  output$tabla_laps <- renderTable({
    req(laps_sel())
    laps_sel() %>% rename(
      Lap=lap_num, `Dist (km)`=lap_dist_km, `Tiempo (s)`=lap_time_s,
      Ritmo=lap_pace_str, `FC media`=lap_hr,
      Cadencia=lap_cadence, `Zancada (m)`=lap_stride)
  }, striped=TRUE, hover=TRUE, na="--")

  # ── Tab 3: Evolucion ────────────────────────────────────────────────────────
  mk_evol_plot <- function(df, y_var, y_label, color, reversed=FALSE) {
    p <- ggplot(df, aes_string(x="fecha", y=y_var)) +
      geom_line(color=color) + geom_point(color=color, size=2) +
      geom_smooth(method="loess", se=TRUE, alpha=0.15, color=color) +
      labs(x=NULL, y=y_label) + theme_minimal()
    if (reversed) p <- p + scale_y_reverse()
    ggplotly(p)
  }

  output$plot_evol_distancia  <- renderPlotly({
    req(sesiones()); mk_evol_plot(sesiones() %>% arrange(fecha),
      "distancia_km", "km", "#1f77b4")})
  output$plot_evol_ritmo      <- renderPlotly({
    req(sesiones()); mk_evol_plot(sesiones() %>% arrange(fecha),
      "ritmo_medio_s", "s/km", "#2ca02c", reversed=TRUE)})
  output$plot_evol_cadencia   <- renderPlotly({
    req(sesiones()); mk_evol_plot(sesiones() %>% arrange(fecha),
      "cadencia_media", "pmm", "#9467bd")})
  output$plot_evol_fc         <- renderPlotly({
    req(sesiones()); mk_evol_plot(sesiones() %>% arrange(fecha),
      "fc_media", "bpm", "#d62728")})
  output$plot_evol_eficiencia <- renderPlotly({
    req(sesiones())
    df <- sesiones() %>% arrange(fecha) %>%
      mutate(eficiencia = ritmo_medio_s / fc_media)
    mk_evol_plot(df, "eficiencia", "s/km/bpm", "#ff7f0e", reversed=TRUE)
  })

  # ── Tab 4: Comparar ─────────────────────────────────────────────────────────
  output$tabla_comp_1 <- renderTable({
    req(sesiones(), input$comp_fecha_1)
    sesiones() %>% filter(fecha == as.Date(input$comp_fecha_1)) %>%
      select(Fecha=fecha, `Dist (km)`=distancia_km, Tiempo=tiempo_hms,
             Ritmo=ritmo_medio, `Cadencia`=cadencia_media, `FC media`=fc_media)
  }, striped=TRUE)

  output$tabla_comp_2 <- renderTable({
    req(sesiones(), input$comp_fecha_2)
    sesiones() %>% filter(fecha == as.Date(input$comp_fecha_2)) %>%
      select(Fecha=fecha, `Dist (km)`=distancia_km, Tiempo=tiempo_hms,
             Ritmo=ritmo_medio, `Cadencia`=cadencia_media, `FC media`=fc_media)
  }, striped=TRUE)

  output$plot_comparacion <- renderPlotly({
    req(sesiones(), input$comp_fecha_1, input$comp_fecha_2)
    df <- sesiones()
    r1 <- df %>% filter(fecha == as.Date(input$comp_fecha_1))
    r2 <- df %>% filter(fecha == as.Date(input$comp_fecha_2))
    if (nrow(r1)==0 || nrow(r2)==0) return(NULL)

    vars <- list(
      list(n="Dist (km)",      v1=r1$distancia_km,   v2=r2$distancia_km),
      list(n="FC media (bpm)", v1=r1$fc_media,       v2=r2$fc_media),
      list(n="Cadencia (pmm)", v1=r1$cadencia_media, v2=r2$cadencia_media),
      list(n="Ritmo (s/km)",   v1=r1$ritmo_medio_s,  v2=r2$ritmo_medio_s)
    )
    comp_df <- bind_rows(lapply(vars, function(v) {
      mx <- max(v$v1, v$v2, na.rm=TRUE)
      data.frame(Metrica=v$n,
                 Sesion=c(as.character(r1$fecha), as.character(r2$fecha)),
                 Valor_norm=c(v$v1/mx*100, v$v2/mx*100),
                 Valor_real=c(v$v1, v$v2))
    }))
    p <- ggplot(comp_df, aes(x=Metrica, y=Valor_norm, fill=Sesion,
                              text=paste("Sesion:", Sesion, "<br>Valor:", round(Valor_real,2)))) +
      geom_bar(stat="identity", position="dodge") +
      scale_fill_manual(values=c("#1f77b4","#ff7f0e")) +
      labs(x=NULL, y="% del maximo") + theme_minimal()
    ggplotly(p, tooltip="text")
  })

  output$plot_comp_telemetria <- renderPlotly({
    req(telemetria(), input$comp_fecha_1, input$comp_fecha_2)
    r1 <- telemetria()[[input$comp_fecha_1]]
    r2 <- telemetria()[[input$comp_fecha_2]]
    if (is.null(r1) || is.null(r2)) return(
      plotly_empty() %>% layout(title="Telemetria no disponible para sesiones CSV"))
    plot_ly() %>%
      add_lines(data=r1, x=~dist_km, y=~hr_bpm, name=input$comp_fecha_1,
                line=list(color="#1f77b4")) %>%
      add_lines(data=r2, x=~dist_km, y=~hr_bpm, name=input$comp_fecha_2,
                line=list(color="#ff7f0e")) %>%
      layout(title="FC vs distancia", xaxis=list(title="Distancia (km)"),
             yaxis=list(title="FC (bpm)"), legend=list(orientation="h"))
  })

  # ── Tab 5: Fisiologia ───────────────────────────────────────────────────────
  zonas_fc <- reactive({
    req(sesiones())
    fc_max_hist <- max(sesiones()$fc_max, na.rm=TRUE)
    list(z1=fc_max_hist*0.60, z2=fc_max_hist*0.70,
         z3=fc_max_hist*0.80, z4=fc_max_hist*0.90, z5=fc_max_hist)
  })

  output$plot_zonas_fc <- renderPlotly({
    rec <- rec_sel(); req(!is.null(rec)); z <- zonas_fc()
    rec <- rec %>% filter(!is.na(hr_bpm)) %>%
      mutate(zona=case_when(
        hr_bpm < z$z1 ~ "Z1 Recuperacion",
        hr_bpm < z$z2 ~ "Z2 Base aerobica",
        hr_bpm < z$z3 ~ "Z3 Tempo",
        hr_bpm < z$z4 ~ "Z4 Umbral",
        TRUE           ~ "Z5 VO2max"))
    dist_zona <- rec %>% group_by(zona) %>%
      summarise(dist=max(dist_km,na.rm=TRUE)-min(dist_km,na.rm=TRUE), .groups="drop")
    p <- ggplot(dist_zona, aes(x=zona, y=dist, fill=zona)) +
      geom_bar(stat="identity") +
      scale_fill_manual(values=c("Z1 Recuperacion"="#3498db","Z2 Base aerobica"="#2ecc71",
                                  "Z3 Tempo"="#f1c40f","Z4 Umbral"="#e67e22","Z5 VO2max"="#e74c3c")) +
      labs(x=NULL, y="km") + theme_minimal() + theme(legend.position="none")
    ggplotly(p)
  })

  output$plot_deriva_fc <- renderPlotly({
    rec <- rec_sel(); req(!is.null(rec))
    rec <- rec %>% filter(!is.na(hr_bpm), !is.na(dist_km))
    p <- ggplot(rec, aes(x=dist_km, y=hr_bpm)) +
      geom_line(color="#e74c3c", alpha=0.5) +
      geom_smooth(method="lm", color="#c0392b", se=FALSE) +
      labs(title="Deriva cardiaca", x="Distancia (km)", y="FC (bpm)") + theme_minimal()
    ggplotly(p)
  })

  output$plot_carga_semanal <- renderPlotly({
    req(sesiones())
    df <- sesiones() %>%
      mutate(semana=floor_date(fecha, "week"),
             fc_norm=fc_media/max(fc_max, na.rm=TRUE),
             carga=distancia_km*fc_norm) %>%
      group_by(semana) %>% summarise(carga_semana=sum(carga,na.rm=TRUE), .groups="drop")
    p <- ggplot(df, aes(x=semana, y=carga_semana,
                         text=paste("Semana:", semana, "<br>Carga:", round(carga_semana,1)))) +
      geom_col(fill="#e67e22") + labs(x=NULL, y="Unidades de carga") + theme_minimal()
    ggplotly(p, tooltip="text")
  })

  # ── Tab 6: Biomecanica ──────────────────────────────────────────────────────
  output$plot_bio_zancada <- renderPlotly({
    rec <- rec_sel(); req(!is.null(rec))
    rec <- rec %>% filter(!is.na(cadence_spm), cadence_spm>0, !is.na(speed_mps)) %>%
      mutate(stride_m=speed_mps/(cadence_spm/60))
    plot_ly(rec, x=~dist_km) %>%
      add_lines(y=~cadence_spm, name="Cadencia (pmm)", line=list(color="#9b59b6")) %>%
      add_lines(y=~stride_m*100, name="Zancada x100 (cm)", line=list(color="#27ae60"), yaxis="y2") %>%
      layout(xaxis=list(title="Distancia (km)"),
             yaxis=list(title="Cadencia (pmm)"),
             yaxis2=list(title="Zancada (cm)", side="right", overlaying="y"),
             legend=list(orientation="h"))
  })

  output$plot_bio_scatter <- renderPlotly({
    rec <- rec_sel(); req(!is.null(rec)); z <- zonas_fc()
    rec <- rec %>% filter(!is.na(cadence_spm), !is.na(speed_mps), !is.na(hr_bpm)) %>%
      mutate(vel_kmh=speed_mps*3.6,
             zona=case_when(hr_bpm<z$z1~"Z1",hr_bpm<z$z2~"Z2",
                            hr_bpm<z$z3~"Z3",hr_bpm<z$z4~"Z4",TRUE~"Z5"))
    p <- ggplot(rec, aes(x=cadence_spm, y=vel_kmh, color=zona,
                          text=paste("Cadencia:",cadence_spm,"<br>Vel:",round(vel_kmh,1),"km/h"))) +
      geom_point(alpha=0.4, size=1) +
      scale_color_manual(values=c(Z1="#3498db",Z2="#2ecc71",Z3="#f1c40f",Z4="#e67e22",Z5="#e74c3c")) +
      labs(x="Cadencia (pmm)", y="Velocidad (km/h)") + theme_minimal()
    ggplotly(p, tooltip="text")
  })

  output$plot_bio_degradacion <- renderPlotly({
    rec <- rec_sel(); req(!is.null(rec))
    rec <- rec %>% filter(!is.na(cadence_spm), !is.na(dist_km))
    mid <- max(rec$dist_km, na.rm=TRUE)/2
    rec <- rec %>% mutate(mitad=ifelse(dist_km<=mid,"Primera mitad","Segunda mitad"))
    p <- ggplot(rec, aes(x=dist_km, y=cadence_spm, color=mitad)) +
      geom_line(alpha=0.6) + geom_smooth(method="loess", se=FALSE) +
      scale_color_manual(values=c("Primera mitad"="#2ecc71","Segunda mitad"="#e74c3c")) +
      labs(x="Distancia (km)", y="Cadencia (pmm)") + theme_minimal()
    ggplotly(p)
  })

  output$plot_bio_laps <- renderPlotly({
    req(laps_sel())
    laps_df <- laps_sel() %>% filter(!is.na(lap_pace_str)) %>%
      mutate(pace_s=sapply(lap_pace_str, pace_str_to_secs))
    p <- ggplot(laps_df, aes(x=lap_num, y=pace_s,
                              text=paste("Lap:",lap_num,"<br>Ritmo:",lap_pace_str))) +
      geom_line(color="#1f77b4") + geom_point(color="#1f77b4", size=3) +
      scale_y_reverse(labels=function(s) secs_to_pace_str(s)) +
      labs(x="Lap", y="Ritmo (min/km)") + theme_minimal()
    ggplotly(p, tooltip="text")
  })

})
