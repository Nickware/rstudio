library(shiny)
library(shinydashboard)
library(DT)
library(plotly)  # Nuevo

ui <- dashboardPage(
  dashboardHeader(title = "Baloto Analyzer"),
  dashboardSidebar(
    actionButton("reintentar", "Actualizar", icon = icon("sync")),
    uiOutput("selector_balota"),
    uiOutput("status")
  ),
  dashboardBody(
    tabBox(
      width = 12,
      tabPanel("Datos", DTOutput("tabla_cruda")),
      tabPanel("Frecuencias", DTOutput("tabla_frecuencias")),
      tabPanel("Gráfico",
               plotlyOutput("histograma"),  # Cambiado a plotlyOutput
               br(),
               uiOutput("hover_info"))  # mostrar valores
    )
  )
)