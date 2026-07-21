# modules/data_import_ui.R
# Interfaz de usuario para el módulo de ingesta de datos
# Versión: 2.0
# Última actualización: Junio 2026

library(shiny)
library(shinyjs)
library(DT)

dataImportUI <- function(id) {
  ns <- NS(id)
  
  tabPanel("Ingesta de Datos",
           sidebarLayout(
             sidebarPanel(
               width = 4,
               h4("Carga de Datos"),
               
               # Selector de modo de carga
               radioButtons(ns("modo_carga"), 
                            "Modo de carga:",
                            choices = c(
                              "Actividad individual" = "individual",
                              "Múltiples individuales" = "multi_individual",
                              "Archivo colectivo (44 actividades)" = "colectivo"
                            ),
                            selected = "individual"),
               
               # Modo: Individual
               conditionalPanel(
                 condition = "input.modo_carga == 'individual'",
                 ns = ns,
                 fileInput(ns("archivo_individual"),
                           "Seleccionar archivo individual",
                           multiple = FALSE,
                           accept = c(".csv", ".CSV")),
                 helpText("Estructura: 44 columnas con métricas por vuelta")
               ),
               
               # Modo: Múltiples individuales
               conditionalPanel(
                 condition = "input.modo_carga == 'multi_individual'",
                 ns = ns,
                 fileInput(ns("archivos_multi"),
                           "Seleccionar múltiples archivos",
                           multiple = TRUE,
                           accept = c(".csv", ".CSV")),
                 helpText("Selecciona varios archivos CSV (Ctrl+clic o Cmd+clic)"),
                 hr(),
                 checkboxGroupInput(ns("seleccion_multi"),
                                    "Actividades a incluir:",
                                    choices = NULL)
               ),
               
               # Modo: Colectivo
               conditionalPanel(
                 condition = "input.modo_carga == 'colectivo'",
                 ns = ns,
                 fileInput(ns("archivo_colectivo"),
                           "Seleccionar archivo colectivo",
                           multiple = FALSE,
                           accept = c(".csv", ".CSV")),
                 helpText("Estructura: 36 columnas con resumen por actividad")
               ),
               
               hr(),
               
               # Metadatos
               selectInput(ns("sujeto"), 
                           "Sujeto",
                           choices = c("Corredor_01", "Corredor_02", "Corredor_03")),
               
               selectInput(ns("superficie"),
                           "Superficie",
                           choices = c("Cinta", "Asfalto")),
               
               hr(),
               
               actionButton(ns("procesar"), 
                            "Procesar y Normalizar",
                            class = "btn-primary btn-block"),
               
               hr(),
               
               verbatimTextOutput(ns("resumen_carga"))
             ),
             
             mainPanel(
               width = 8,
               tabsetPanel(
                 tabPanel("Vista Previa",
                          conditionalPanel(
                            condition = "input.modo_carga == 'individual'",
                            ns = ns,
                            DTOutput(ns("preview_individual"))
                          ),
                          conditionalPanel(
                            condition = "input.modo_carga == 'colectivo'",
                            ns = ns,
                            DTOutput(ns("preview_colectivo"))
                          ),
                          conditionalPanel(
                            condition = "input.modo_carga == 'multi_individual'",
                            ns = ns,
                            uiOutput(ns("preview_multi"))
                          )
                 ),
                 
                 tabPanel("Estructura Detectada",
                          verbatimTextOutput(ns("info_estructura"))
                 ),
                 
                 tabPanel("Datos Normalizados",
                          DTOutput(ns("preview_normalizado"))
                 ),
                 
                 tabPanel("Estadísticas",
                          plotOutput(ns("distribucion_metricas")),
                          br(),
                          plotOutput(ns("evolucion_temporal"))
                 )
               )
             )
           )
  )
}