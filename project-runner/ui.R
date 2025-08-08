library(shiny)
library(shinydashboard)
library(plotly)

shinyUI(dashboardPage(
  dashboardHeader(title = "Running Dashboard"),
  
  dashboardSidebar(sidebarMenu(
    menuItem("Data File", tabName = "data_file", icon = icon("th")),
    menuItem("Informacion General", tabName = "informacion_general", icon = icon("dashboard")),
    menuItem("Run Info", tabName = "run_info", icon = icon("dashboard")),
    menuItem("Cardio Info", tabName = "cardio_info", icon = icon("heart")),
    menuItem("Comparar actividades", tabName = "comparar_actividades", icon = icon("balance-scale"))
  )),
  
  dashboardBody(tabItems(
    
    # 1. Subida de archivo
    tabItem(tabName = "data_file",
            fluidPage(
              titlePanel("Uploading Files"),
              sidebarLayout(
                sidebarPanel(
                  fileInput("file1", "Choose CSV File", multiple = FALSE,
                            accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")),
                  tags$hr(),
                  checkboxInput("header", "Header", TRUE),
                  radioButtons("sep", "Separator", choices = c(Comma = ",", Semicolon = ";", Tab = "\t"), selected = ","),
                  radioButtons("quote", "Quote", choices = c(None = "", "Double Quote" = '"', "Single Quote" = "'"), selected = '"'),
                  tags$hr(),
                  radioButtons("disp", "Display", choices = c(Head = "head", All = "all"), selected = "head")
                ),
                mainPanel(tableOutput("contents"))
              )
            )
    ),
    
    # 2. Información General
    tabItem(tabName = "informacion_general",
            box(
              width = 12,  # Usar ancho completo (12 es el máximo en fluidRow)
              title = "Histograma de Actividades",
              status = "primary",
              solidHeader = TRUE,
              plotlyOutput("actividad_histograma", height = "400px")  # Solo especificar altura
            ),
            fluidRow(
              valueBoxOutput("total_activities_box"),
              valueBoxOutput("total_distance_box"),
              valueBoxOutput("total_time_box"),
              valueBoxOutput("total_average_pace_box"),
              valueBoxOutput("total_average_running_box"),
              valueBoxOutput("total_average_stride_box")
            )
    ),
    
    # 3. Información de carrera
    tabItem(tabName = "run_info",
            box(
              width = 4,
              title = "Fecha",
              status = "warning",
              solidHeader = TRUE,
              selectInput("Fecha", "Date", choices = NULL)  # se actualiza en server.R
            ),
            fluidRow(
              box(width = 2, title = "Distancia", background = "maroon", solidHeader = TRUE,
                  numericInput("Distancia", "Distance (km)", value = 0, step = 0.01, min = 0, max = 100, width = "100%")),
              box(width = 2, title = "Tiempo", background = "blue", solidHeader = TRUE,
                  textInput("Tiempo", "Time (hh:mm:ss)", value = "", width = "100%")),
              box(width = 2, title = "Ritmo Medio", background = "green", solidHeader = TRUE,
                  textInput("Ritmo.medio", "Average pace (mm:ss)", value = "", width = "100%")),
              box(width = 2, title = "Cadencia media de Carrera", background = "purple", solidHeader = TRUE,
                  numericInput("Cadencia.de.carrera.media", "Average running cadence (pmm)", value = 0, step = 1, min = 0, max = 10000, width = "100%")),
              box(width = 2, title = "Longitud media de Zancada", background = "navy", solidHeader = TRUE,
                  numericInput("Longitud.media.de.zancada", "Average stride length (m)", value = 0, step = 0.01, min = 0, max = 200, width = "100%"))
            ),
            box(
              width = 4,
              title = "Running Performance",
              status = "warning",
              solidHeader = TRUE,
            ),
            fluidRow(
              box(width = 2, title = "Calorias", background = "light-blue", solidHeader = TRUE,
                  textInput("calorias", "Calories (Energy)", value = "", width = "100%")),
              box(width = 2, title = "Pulsaciones", background = "yellow", solidHeader = TRUE,
                  textInput("Frecuencia.cardiaca.media", "Heart rate (bpm)", value = "", width = "100%")),
              box(width = 2, title = "TE anaeróbico", background = "fuchsia", solidHeader = TRUE,
                  textInput("TE.aeróbico", "Aerobic Training Effect", value = "", width = "100%"))
            )
    ),
    
    # 4. Información cardiovascular
    tabItem(tabName = "cardio_info",
            box(
              width = 5,
              title = "Fecha",
              status = "danger",
              solidHeader = TRUE,
              selectInput("Fecha_i2", "Date", choices = NULL)  # se actualiza en server.R
            ),
            box(plotOutput("temperature_plot", height = 400, width = "100%")),
            box(plotOutput("height_plot", height = 400, width = "100%"))
    ), 

    # 5. Comparar actividades
    tabItem(tabName = "comparar_actividades",
            fluidRow(
              box(
                width = 6,
                title = "Actividad_1",
                status = "primary",
                solidHeader = TRUE,
                selectInput("comp_fecha_1", "Fecha Actividad 1", choices = NULL),  # se actualiza en server.R
                tableOutput("tabla_actividad_1")  # se actualiza en server.R
              ),
              box(
                width = 6,
                title = "Actividad_2",
                status = "success",
                solidHeader = TRUE,
                selectInput("comp_fecha_2", "Fecha Actividad 2", choices = NULL),  # se actualiza en server.R
                tableOutput("tabla_actividad_2")  # se actualiza en server.R
              )
            ),
            fluidRow(
              box(width = 12, title="Comparación Gráfica", status = "info",
              plotlyOutput("comparison_plot", height = "400px"))
            )
            )
  ))
))

