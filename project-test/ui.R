library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(shinyjs)

ui <- dashboardPage(
  dashboardHeader(
    title = span("Baloto Analyzer ", 
                 tags$small("Investigación Estadística")),
    titleWidth = 300
  ),
  
  dashboardSidebar(
    sidebarMenu(
      id = "main_menu",
      menuItem("Base de Datos", 
               tabName = "datos", 
               icon = icon("database")),
      
      menuItem("Análisis Univariado", 
               icon = icon("chart-column"),
               menuSubItem("Distribuciones", tabName = "distribuciones"),
               menuSubItem("Tendencias", tabName = "tendencias")),
      
      menuItem("Análisis Multivariado", 
               icon = icon("project-diagram"),
               menuSubItem("Por Posición", tabName = "posicion"),
               menuSubItem("Correlaciones", tabName = "correlaciones")),
      
      menuItem("Validación Estadística", 
               icon = icon("flask"),
               menuSubItem("Pruebas", tabName = "pruebas"),
               menuSubItem("Aleatoriedad", tabName = "aleatoriedad")),
      
      div(class = "sidebar-controls",
          actionButton("reintentar", "Actualizar Datos", 
                       icon = icon("rotate"), 
                       class = "btn-primary",
                       style = "width: 90%; margin: 10px auto;"),
          uiOutput("selector_balota")
      ),
      
      tags$footer(style = "padding: 10px; text-align: center;",
                  tags$small("Versión 1.0 - © 2023"))
    ),
    width = 250
  ),
  
  dashboardBody(
    useShinyjs(),
    tags$head(
      tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css"),
      tags$style(HTML("
        /* Estilos personalizados */
        .main-header .logo {
          font-weight: 300;
          font-size: 1.2em;
        }
        .sidebar-controls {
          background: rgba(0,0,0,0.05);
          padding: 10px 5px;
          margin: 10px 5px;
          border-radius: 5px;
        }
        .box-title {
          font-weight: 400 !important;
          font-size: 1.1em;
        }
        .box {
          margin-top: 5px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .nav-tabs-custom {
          box-shadow: none;
        }
        .info-box {
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .content-wrapper {
          background-color: #f9f9f9;
        }
        .btn-download {
          background-color: #28a745;
          color: white;
          border: none;
          width: 100%;
          margin-top: 10px;
        }
      "))
    ),
    
    tabItems(
      # 1. BASE DE DATOS
      tabItem(tabName = "datos",
              fluidRow(
                box(title = "Conjunto de Datos Completos",
                    width = 12,
                    status = "primary",
                    solidHeader = TRUE,
                    helpText("Datos históricos de todos los sorteos registrados. Filtre por fechas usando los controles superiores."),
                    DTOutput("tabla_cruda"),
                    footer = "Fuente oficial: Baloto Colombia. Última actualización: ", 
                    textOutput("fecha_actualizacion", inline = TRUE))
              )
      ),
      
      # 2.1 DISTRIBUCIONES (UNIVARIADO)
      tabItem(tabName = "distribuciones",
              fluidRow(
                box(title = "Distribución de Frecuencias",
                    width = 6,
                    status = "info",
                    plotlyOutput("histograma"),
                    footer = "Histograma interactivo de frecuencias absolutas."),
                
                box(title = "Medidas de Posición",
                    width = 6,
                    status = "info",
                    plotlyOutput("boxplot_posiciones"),
                    footer = "Diagramas de caja por posición en el sorteo.")
              ),
              fluidRow(
                box(title = "Estadísticos Descriptivos",
                    width = 12,
                    status = "info",
                    DTOutput("tabla_frecuencias"),
                    footer = "Medidas de tendencia central y dispersión para cada número.")
              )
      ),
      
      # 2.2 TENDENCIAS (UNIVARIADO)
      tabItem(tabName = "tendencias",
              fluidRow(
                box(title = "Series Temporales",
                    width = 12,
                    status = "info",
                    plotlyOutput("series_temporales"),
                    footer = "Evolución de frecuencias acumuladas a través del tiempo.")
              )
      ),
      
      # 3.1 ANÁLISIS POR POSICIÓN (MULTIVARIADO) - ACTUALIZADO
      tabItem(tabName = "posicion",
              fluidRow(
                box(title = "Mapa de Calor por Posición",
                    width = 6,
                    status = "danger",
                    solidHeader = TRUE,
                    plotlyOutput("heatmap_posicion"),
                    footer = "Frecuencia relativa de cada número en cada posición. Pase el mouse para ver detalles."),
                
                box(title = "Distribución por Balota",
                    width = 6,
                    status = "danger",
                    solidHeader = TRUE,
                    plotlyOutput("histograma_posicion"),
                    footer = "Comparación de distribuciones entre diferentes posiciones.")
              ),
              fluidRow(
                box(title = "Tabla de Contingencia Detallada",
                    width = 8,
                    status = "danger",
                    solidHeader = TRUE,
                    DTOutput("tabla_posicion"),
                    footer = "Frecuencias observadas por posición. Use búsqueda para filtrar."),
                
                box(title = "Acciones",
                    width = 4,
                    status = "danger",
                    solidHeader = TRUE,
                    downloadButton("descargar_posicion", "Exportar CSV", 
                                   class = "btn-download"),
                    br(),
                    actionButton("actualizar_analisis", "Actualizar Análisis",
                                 icon = icon("refresh"),
                                 style = "width: 100%; margin-top: 10px;"),
                    footer = "Descargue los datos completos del análisis.")
              )
      ),
      
      # 3.2 CORRELACIONES (MULTIVARIADO)
      tabItem(tabName = "correlaciones",
              fluidRow(
                box(title = "Matriz de Correlación",
                    width = 6,
                    status = "danger",
                    plotlyOutput("matriz_correlacion"),
                    footer = "Coeficientes de correlación entre posiciones."),
                
                box(title = "Análisis de Autocorrelación",
                    width = 6,
                    status = "danger",
                    plotOutput("acf_plots"),
                    footer = "Función de autocorrelación para validar independencia.")
              )
      ),
      
      # 4.1 PRUEBAS ESTADÍSTICAS
      tabItem(tabName = "pruebas",
              fluidRow(
                box(title = "Pruebas de Uniformidad",
                    width = 6,
                    status = "warning",
                    verbatimTextOutput("resultados_tests"),
                    footer = "Resultados de Chi-cuadrado y Kolmogorov-Smirnov."),
                
                box(title = "Gráficos de Control",
                    width = 6,
                    status = "warning",
                    plotOutput("grafico_control"),
                    footer = "Límites 3σ para frecuencias observadas vs esperadas.")
              )
      ),
      
      # 4.2 ALEATORIEDAD
      tabItem(tabName = "aleatoriedad",
              fluidRow(
                box(title = "Test de Rachas",
                    width = 6,
                    status = "warning",
                    verbatimTextOutput("test_rachas"),
                    footer = "Prueba de aleatoriedad basada en secuencias."),
                
                box(title = "Test de Permutaciones",
                    width = 6,
                    status = "warning",
                    verbatimTextOutput("test_permutaciones"),
                    footer = "Validación de patrones mediante permutaciones aleatorias.")
              )
      )
    )
  )
)