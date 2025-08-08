library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(shinyjs)

ui <- dashboardPage(
  dashboardHeader(title = "Baloto Analyzer"),
  dashboardSidebar(
    sidebarMenu(
      id = "main_menu",
      # --- MÓDULO SORTEO REAL ---
      menuItem("Sorteo Real", 
               icon = icon("search"), 
               startExpanded = TRUE,
               menuSubItem("Datos Históricos", tabName = "historico"),
               menuSubItem("Histogramas y Frecuencias", tabName = "histograma_frecuencias"),
               menuSubItem("Análisis por Posición", tabName = "posicion"),
               
               # Controles específicos del módulo
               div(class = "sidebar-controls",
                   actionButton("reintentar", "Actualizar Datos", 
                                icon = icon("sync"), 
                                style = "margin: 10px 15px; width: 85%"),
                   uiOutput("selector_balota")
               )
      ),
      
      # --- MÓDULOS FUTUROS ---
      menuItem("Simulación", 
               icon = icon("dice"), 
               tabName = "simulacion"),
      
      menuItem("Predicción", 
               icon = icon("chart-line"), 
               tabName = "prediccion")
    )
  ),
  
  dashboardBody(
    useShinyjs(),  # Para mostrar/ocultar controles
    tabItems(
      # --- DATOS HISTÓRICOS ---
      tabItem(tabName = "historico",
              box(title = "Datos Completos de Sorteos",
                  DTOutput("tabla_cruda"),
                  width = 12,
                  status = "primary")
      ),
      
      # --- HISTOGRAMA Y FRECUENCIAS GLOBALES (COMBINADOS) ---
      tabItem(tabName = "histograma_frecuencias",
              fluidRow(
                box(title = "Distribución por Balota (Histogramas)",
                    plotlyOutput("histograma"),
                    width = 12,
                    status = "primary")
              ),
              fluidRow(
                box(title = "Conteo de Números (Frecuencias Globales)",
                    DTOutput("tabla_frecuencias"),
                    width = 12,
                    status = "primary")
              )
      ),
      
      # --- ANÁLISIS POR POSICIÓN ---
      tabItem(tabName = "posicion",
              fluidRow(
                box(title = "Heatmap de Frecuencias por Posición",
                    plotlyOutput("heatmap_posicion"),
                    width = 12,
                    status = "info",
                    footer = "Cada celda muestra la frecuencia del número en esa posición")
              ),
              fluidRow(
                box(title = "Tabla Detallada por Posición",
                    DTOutput("tabla_posicion"),
                    width = 12,
                    status = "info",
                    footer = downloadButton("descargar_posicion", 
                                            "Exportar CSV",
                                            style = "width:100%;"))
              )
      ),
      
      # --- MÓDULOS FUTUROS (Placeholders) ---
      tabItem(tabName = "simulacion",
              h3("Módulo de Simulación en Desarrollo",
                 style = "text-align: center; margin-top: 100px;")),
      
      tabItem(tabName = "prediccion",
              h3("Módulo de Predicción en Desarrollo",
                 style = "text-align: center; margin-top: 100px;"))
    ),
    
    # Estilos CSS personalizados
    tags$head(
      tags$style(HTML("
        .sidebar-controls {
          background: #f8f9fa;
          padding: 10px;
          margin: 10px;
          border-radius: 5px;
          border: 1px solid #dee2e6;
        }
        .box-title {
          font-weight: bold !important;
        }
        #descargar_posicion {
          background-color: #28a745;
          color: white;
          border: none;
        }
        /* Espaciado entre boxes */
        .box {
          margin-bottom: 20px;
        }
      "))
    )
  )
)