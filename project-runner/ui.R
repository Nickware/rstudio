# Load required packages
library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(tidyr)

# Read in data from CSV file
df <- read.csv("files/activities.csv", header = TRUE)
names(df)[names(df) == "Calorías"] <- "calorias"

# Convert datetime column to POSIXct format
df$Fecha <- as.POSIXct(df$Fecha)

# Define UI for Shiny app
# Define UI
shinyUI(dashboardPage(
  dashboardHeader(title = "Running Dashboard"),
  dashboardSidebar(sidebarMenu(
    menuItem("Data File", tabName = "data_file", icon = icon("th")),
    menuItem("Run Info", tabName = "run_info", icon = icon("dashboard")),
    menuItem("Cardio Info", tabName = "cardio_info", icon = icon("heart"))
    
  )),
  dashboardBody(tabItems(
    tabItem(tabName = "data_file",
            #h2("Widgets tab content"),
            #output$upload_data_ui <- renderUI({
              # Define UI for data upload app ----
              ui <- fluidPage(# App title ----
                              titlePanel("Uploading Files"),
                              
                              # Sidebar layout with input and output definitions ----
                              sidebarLayout(
                                # Sidebar panel for inputs ----
                                sidebarPanel(
                                  # Input: Select a file ----
                                  fileInput(
                                    "file1",
                                    "Choose CSV File",
                                    multiple = FALSE,
                                    accept = c(
                                      "text/csv",
                                      "text/comma-separated-values,text/plain",
                                      ".csv"
                                    )
                                  ),
                                  
                                  # Horizontal line ----
                                  tags$hr(),
                                  
                                  # Input: Checkbox if file has header ----
                                  checkboxInput("header", "Header", TRUE),
                                  
                                  # Input: Select separator ----
                                  radioButtons(
                                    "sep",
                                    "Separator",
                                    choices = c(
                                      Comma = ",",
                                      Semicolon = ";",
                                      Tab = "\t"
                                    ),
                                    selected = ","
                                  ),
                                  
                                  # Input: Select quotes ----
                                  radioButtons(
                                    "quote",
                                    "Quote",
                                    choices = c(
                                      None = "",
                                      "Double Quote" = '"',
                                      "Single Quote" = "'"
                                    ),
                                    selected = '"'
                                  ),
                                  
                                  # Horizontal line ----
                                  tags$hr(),
                                  
                                  # Input: Select number of rows to display ----
                                  radioButtons(
                                    "disp",
                                    "Display",
                                    choices = c(Head = "head",
                                                All = "all"),
                                    selected = "head"
                                  )
                                  
                                ),
                                
                                # Main panel for displaying outputs ----
                                mainPanel(# Output: Data file ----
                                          tableOutput("contents"))
                                
                              ))
            ),
    #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
    tabItem(
      tabName = "run_info",
      #h2("Dynamic Profile"),
      box(
        width = 5,
        title = "Fecha",
        status = "warning",
        solidHeader = TRUE,
        selectInput("Fecha", "Date",  choices = unique(df$Fecha))
      ),
      fluidRow(
        box(
          width = 2,
          title = "Distancia",
          background = "maroon",
          solidHeader = TRUE,
          numericInput(
            "Distancia",
            "Distance (km)",
            value = 0,
            step = 0.01,
            min = 0,
            max = 100,
            width = "100%"
          )
        ),
        box(
          width = 2,
          title = "Tiempo",
          background = "blue",
          solidHeader = TRUE,
          textInput(
            "Tiempo",
            "Time (hh:mm:ss)",
            value = "",
            width = "100%"
          )
        ),
        box(
          width = 2,
          title = "Ritmo Medio",
          background = "green",
          solidHeader = TRUE,
          textInput(
            "Ritmo.medio",
            "Average pace (mm:ss)",
            value = "",
            width = "100%"
          )
        ),
        box(
          width = 2,
          title = "Cadencia media de Carrera",
          background = "purple",
          solidHeader = TRUE,
          numericInput(
            "Cadencia.de.carrera.media",
            "Average running cadence (pmm)",
            value = 0,
            step = 1,
            min = 0,
            max = 10000,
            width = "100%"
          )
        ),
        box(
          width = 2,
          title = "Longitud media de Zancada",
          background = "navy",
          solidHeader = TRUE,
          numericInput(
            "Longitud.media.de.zancada",
            "Average stride length (m)",
            value = 0,
            step = 0.01,
            min = 0,
            max = 200,
            width = "100%"
          )
        ),
        #valueBox(10*2, "Total número de actividades", icon = icon("credit-card")),
        
        # Dynamic valueBoxes
        valueBoxOutput("total_activities_box"),
        
        valueBoxOutput("total_distance_box"),
        
        valueBoxOutput("total_time_box"),
        
        valueBoxOutput("total_average_pace_box"),
        
        valueBoxOutput("total_average_running_box"),
        
        valueBoxOutput("total_average_stride_box")
      )
    ),
    tabItem(
      tabName = "cardio_info",
      box(
        width = 5,
        title = "Fecha",
        status = "danger",
        solidHeader = TRUE,
        selectInput("Fecha_i2", "Date",  choices = unique(df$Fecha))
      ),
      #dateInput("Fecha__i2", "Date",  value = unique(df$Fecha)[1])),
      #dateInput("Fecha_i2", "Date",  value = unique(df$Fecha)[1], min = min(df$Fecha), max = max(df$Fecha))),
      #dateInput("Fecha_i2", "Date",  value = unique(df$Fecha)[1], min = min(df$Fecha), max = max(df$Fecha))),
      
      fluidRow(
        box(
          width = 2,
          title = "Calorias",
          background = "light-blue",
          solidHeader = TRUE,
          textInput(
            "calorias",
            "Calories (Energy)",
            value = "",
            width = "100%"
          )
        ),
        box(
          width = 2,
          title = "Pulsaciones",
          background = "yellow",
          solidHeader = TRUE,
          textInput(
            "Frecuencia.cardiaca.media",
            "Heart rate (bpm)",
            value = "",
            width = "100%"
          )
        ),
        box(
          width = 2,
          title = "TE anaeróbico",
          background = "fuchsia",
          solidHeader = TRUE,
          textInput(
            "TE.aeróbico",
            "Aerobic Training Efect ",
            value = "",
            width = "100%"
          )
        )
      ),
      box(plotOutput("temperature_plot", height = 400)),
      box(plotOutput("height_plot", height = 400))
      
      #valueBoxOutput("total_calories_box")
    )
  ))
))
