library(shiny)
library(shinydashboard)
library(ggplot2)
library(cowplot)

# ---- Header ----
header <- dashboardHeader(title = "Baloto Analyzer")

# ---- Sidebar ----
sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Presentación", tabName = "presentacion", icon = icon("home")),
    menuItem("Sorteo Real", tabName = "sorteo_real", icon = icon("chart-bar"))
  )
)

# ---- Body ----
body <- dashboardBody(
  tabItems(
    # Página de Presentación
    tabItem(
      tabName = "presentacion",
      h2("Análisis Estadístico de Sorteos Baloto"),
      p("Este dashboard permite validar la aleatoriedad de los sorteos históricos."),
      img(src = "baloto_logo.png", height = 200)
    ),
    
    # Página de Sorteo Real
    tabItem(
      tabName = "sorteo_real",
      h2("Análisis de Sorteos Reales"),
      fluidRow(
        box(
          title = "Paso 1: Cargar Datos",
          dateRangeInput("rango_fechas", "Seleccione el período:", 
                         start = "2023-01-01", end = Sys.Date()),
          actionButton("cargar", "Cargar Datos", icon = icon("download"))
        )
      ),
      fluidRow(
        box(
          title = "Paso 2: Resumen de Frecuencias",
          tableOutput("resumen_frecuencias"),
          width = 6
        ),
        box(
          title = "Paso 4: Test de Uniformidad",
          verbatimTextOutput("test_uniformidad"),
          width = 6
        )
      ),
      fluidRow(
        box(
          title = "Paso 3: Visualización",
          plotOutput("grafico_frecuencias"),
          width = 12
        )
      )
    )
  )
)

# ---- UI Final ----
ui <- dashboardPage(header, sidebar, body)