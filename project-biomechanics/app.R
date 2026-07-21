# app.R
# Punto de entrada de la aplicación
# Versión: 1.0
# Última actualización: Junio 2026

library(shiny)
library(shinydashboard)
library(shinyjs)
library(tidyverse)
library(DT)

# Fuentes de los módulos
source("modules/data_import_ui.R")
source("modules/data_import_server.R")

# UI Principal
ui <- dashboardPage(
  dashboardHeader(title = "Running Biomechanics - Estudio Longitudinal"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Ingesta de Datos", tabName = "import", icon = icon("upload")),
      menuItem("Análisis Temporal", tabName = "analysis", icon = icon("chart-line")),
      menuItem("Modelo Oscilador", tabName = "oscilador", icon = icon("waveform"))
    )
  ),
  dashboardBody(
    useShinyjs(),
    tabItems(
      tabItem(tabName = "import",
              dataImportUI("data_import"))
    )
  )
)

# Server Principal
server <- function(input, output, session) {
  datos <- dataImportServer("data_import")
  
  observe({
    req(datos())
    print(paste("📊 Datos normalizados listos:", nrow(datos()), "registros"))
  })
}

# Ejecutar aplicación
shinyApp(ui, server)