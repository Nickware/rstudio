# ══════════════════════════════════════════════════════════════════════════════
# ui.R — Running Biomechanics Dashboard
# 6 tabs: Datos · Sesión · Evolución · Comparar · Fisiología · Biomecánica
# ══════════════════════════════════════════════════════════════════════════════

library(shiny)
library(shinydashboard)
library(plotly)

shinyUI(dashboardPage(
  skin = "blue",

  # ── Header ────────────────────────────────────────────────────────────────
  dashboardHeader(
    title = "Running Dashboard",
    tags$li(class = "dropdown",
            tags$li(class = "dropdown",
                    textOutput("n_sesiones"),
                    style = "padding: 15px 20px; color: white; font-weight: bold;"))
  ),

  # ── Sidebar ───────────────────────────────────────────────────────────────
  dashboardSidebar(
    sidebarMenu(
      menuItem("Datos",        tabName = "tab_datos",      icon = icon("upload")),
      menuItem("Sesión",       tabName = "tab_sesion",     icon = icon("running")),
      menuItem("Evolución",    tabName = "tab_evolucion",  icon = icon("chart-line")),
      menuItem("Comparar",     tabName = "tab_comparar",   icon = icon("balance-scale")),
      menuItem("Fisiología",   tabName = "tab_fisiologia", icon = icon("heartbeat")),
      menuItem("Biomecánica",  tabName = "tab_biomecanica",icon = icon("shoe-prints"))
    )
  ),

  # ── Body ──────────────────────────────────────────────────────────────────
  dashboardBody(

    # CSS mínimo para separación visual
    tags$head(tags$style(HTML("
      .content-wrapper { background-color: #f4f6f9; }
      .box { border-radius: 4px; }
      .value-box .inner { padding: 10px; }
    "))),

    tabItems(

      # ══════════════════════════════════════════════════════════════════════
      # TAB 1 — DATOS: carga de archivos .fit
      # ══════════════════════════════════════════════════════════════════════
      tabItem(tabName = "tab_datos",
        fluidRow(
          box(
            width = 12, title = "Cargar sesiones de entrenamiento (.fit)",
            status = "primary", solidHeader = TRUE,
            fluidRow(
            column(6,
              fileInput(
                "fit_files",
                label    = "Archivos .fit de Garmin (telemetria completa)",
                multiple = TRUE,
                accept   = ".fit",
                buttonLabel = "Buscar .fit...",
                placeholder = "Sin archivos seleccionados"
              )
            ),
            column(6,
              fileInput(
                "csv_files",
                label    = "Archivos .csv de Garmin Connect (resumen por sesion)",
                multiple = TRUE,
                accept   = c(".csv","text/csv"),
                buttonLabel = "Buscar .csv...",
                placeholder = "Sin archivos seleccionados"
              )
            )
          ),
          tags$div(class = "alert alert-info",
            tags$strong("Tip: "),
            "Los .fit contienen telemetria segundo a segundo (tabs Sesion, Biomecanica y Fisiologia). ",
            "Los .csv son el resumen de Garmin Connect y alimentan las tabs de Evolucion y Comparacion. ",
            "Puedes cargar ambos formatos al mismo tiempo."
          )
          )
        ),
        fluidRow(
          box(
            width = 12, title = "Sesiones cargadas",
            status = "info", solidHeader = TRUE,
            uiOutput("errores_carga"),
            tableOutput("tabla_sesiones")
          )
        )
      ),

      # ══════════════════════════════════════════════════════════════════════
      # TAB 2 — SESIÓN: ficha detallada + telemetría intrasesión
      # ══════════════════════════════════════════════════════════════════════
      tabItem(tabName = "tab_sesion",
        fluidRow(
          box(width = 4, title = "Seleccionar sesión", status = "warning", solidHeader = TRUE,
              selectInput("sel_fecha_sesion", "Fecha", choices = NULL))
        ),
        fluidRow(
          valueBoxOutput("box_dist"),
          valueBoxOutput("box_tiempo"),
          valueBoxOutput("box_ritmo"),
          valueBoxOutput("box_cad"),
          valueBoxOutput("box_fc"),
          valueBoxOutput("box_fc_max")
        ),
        fluidRow(
          box(width = 12, title = "FC y Ritmo a lo largo de la sesión",
              status = "primary", solidHeader = TRUE,
              plotlyOutput("plot_sesion_fc_ritmo", height = "350px"))
        ),
        fluidRow(
          box(width = 12, title = "Cadencia y Altitud",
              status = "info", solidHeader = TRUE,
              plotlyOutput("plot_sesion_cad_alt", height = "300px"))
        ),
        fluidRow(
          box(width = 12, title = "Análisis por laps (km a km)",
              status = "success", solidHeader = TRUE,
              tableOutput("tabla_laps"))
        )
      ),

      # ══════════════════════════════════════════════════════════════════════
      # TAB 3 — EVOLUCIÓN: series longitudinales
      # ══════════════════════════════════════════════════════════════════════
      tabItem(tabName = "tab_evolucion",
        fluidRow(
          box(width = 6, title = "Distancia por sesión",
              status = "primary", solidHeader = TRUE,
              plotlyOutput("plot_evol_distancia", height = "280px")),
          box(width = 6, title = "Ritmo medio por sesión",
              status = "success", solidHeader = TRUE,
              plotlyOutput("plot_evol_ritmo", height = "280px"))
        ),
        fluidRow(
          box(width = 6, title = "Cadencia media por sesión",
              status = "info", solidHeader = TRUE,
              plotlyOutput("plot_evol_cadencia", height = "280px")),
          box(width = 6, title = "FC media por sesión",
              status = "danger", solidHeader = TRUE,
              plotlyOutput("plot_evol_fc", height = "280px"))
        ),
        fluidRow(
          box(width = 12, title = "Eficiencia aeróbica (ritmo/FC) — ↓ mejor",
              status = "warning", solidHeader = TRUE,
              plotlyOutput("plot_evol_eficiencia", height = "280px"))
        )
      ),

      # ══════════════════════════════════════════════════════════════════════
      # TAB 4 — COMPARAR: dos sesiones
      # ══════════════════════════════════════════════════════════════════════
      tabItem(tabName = "tab_comparar",
        fluidRow(
          box(width = 6, title = "Sesión 1", status = "primary", solidHeader = TRUE,
              selectInput("comp_fecha_1", "Fecha", choices = NULL),
              tableOutput("tabla_comp_1")),
          box(width = 6, title = "Sesión 2", status = "success", solidHeader = TRUE,
              selectInput("comp_fecha_2", "Fecha", choices = NULL),
              tableOutput("tabla_comp_2"))
        ),
        fluidRow(
          box(width = 12, title = "Comparación normalizada de métricas",
              status = "info", solidHeader = TRUE,
              plotlyOutput("plot_comparacion", height = "350px"))
        ),
        fluidRow(
          box(width = 12, title = "FC vs distancia — superposición de sesiones",
              status = "warning", solidHeader = TRUE,
              plotlyOutput("plot_comp_telemetria", height = "300px"))
        )
      ),

      # ══════════════════════════════════════════════════════════════════════
      # TAB 5 — FISIOLOGÍA
      # ══════════════════════════════════════════════════════════════════════
      tabItem(tabName = "tab_fisiologia",
        fluidRow(
          box(width = 4, title = "Sesión", status = "danger", solidHeader = TRUE,
              selectInput("sel_fecha_cardio", "Fecha", choices = NULL))
        ),
        fluidRow(
          box(width = 6, title = "Distribución por zonas de FC",
              status = "danger", solidHeader = TRUE,
              plotlyOutput("plot_zonas_fc", height = "320px")),
          box(width = 6, title = "Deriva cardiaca (fatiga intrasesión)",
              status = "warning", solidHeader = TRUE,
              plotlyOutput("plot_deriva_fc", height = "320px"))
        ),
        fluidRow(
          box(width = 12, title = "Carga de entrenamiento semanal",
              status = "primary", solidHeader = TRUE,
              plotlyOutput("plot_carga_semanal", height = "300px"))
        )
      ),

      # ══════════════════════════════════════════════════════════════════════
      # TAB 6 — BIOMECÁNICA
      # ══════════════════════════════════════════════════════════════════════
      tabItem(tabName = "tab_biomecanica",
        fluidRow(
          box(width = 4, title = "Sesión", status = "info", solidHeader = TRUE,
              selectInput("sel_fecha_bio", "Fecha", choices = NULL))
        ),
        fluidRow(
          box(width = 12, title = "Cadencia vs Longitud de zancada",
              status = "info", solidHeader = TRUE,
              plotlyOutput("plot_bio_zancada", height = "320px"))
        ),
        fluidRow(
          box(width = 6, title = "Cadencia vs Velocidad (por zona FC)",
              status = "primary", solidHeader = TRUE,
              plotlyOutput("plot_bio_scatter", height = "320px")),
          box(width = 6, title = "Degradación de cadencia (1ª vs 2ª mitad)",
              status = "warning", solidHeader = TRUE,
              plotlyOutput("plot_bio_degradacion", height = "320px"))
        ),
        fluidRow(
          box(width = 12, title = "Ritmo por lap — análisis de consistencia",
              status = "success", solidHeader = TRUE,
              plotlyOutput("plot_bio_laps", height = "280px"))
        )
      )

    ) # / tabItems
  )   # / dashboardBody
))
