library(shiny)
library(shinydashboard)
library(DT)

ui <- dashboardPage(
  dashboardHeader(title = "Sorteos Baloto"),
  dashboardSidebar(
    actionButton("reintentar", "Reintentar", 
                 icon = icon("sync"),
                 class = "btn-primary"),
    uiOutput("status")
  ),
  dashboardBody(
    box(
      title = "Ultimos registros",
      width = 12,
      DTOutput("tabla_cruda")
    )
  )
)