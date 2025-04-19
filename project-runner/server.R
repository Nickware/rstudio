# Define server logic

shinyServer <- function(input, output, session) {
  output$contents <- renderTable({
    # input$file1 will be NULL initially. After the user selects
    # and uploads a file, head of that data file by default,
    # or all rows if selected, will be shown.
    
    req(input$file1)
    
    # when reading semicolon separated files,
    # having a comma separator causes `read.csv` to error
    tryCatch({
      df <- read.csv(
        input$file1$datapath,
        header = input$header,
        sep = input$sep,
        quote = input$quote
      )
    },
    error = function(e) {
      # return a safeError if a parsing error occurs
      stop(safeError(e))
    })
    
    if (input$disp == "head") {
      return(head(df))
    }
    else {
      return(df)
    }
    
  })
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
df <- read.csv("files/activities.csv", header = TRUE)
names(df)[names(df) == "Calorías"] <- "calorias"
df$Fecha <- as.POSIXct(df$Fecha)

# Update inputs when date is selected tabItem I
observeEvent(input$Fecha, {
  # Filter data based on selected date
  selected_run <- df %>% filter(Fecha == input$Fecha)
  print(selected_run)
  # Update input values
  updateNumericInput(session, "Distancia", value = selected_run$Distancia)
  updateTextInput(session, "Tiempo", value = selected_run$Tiempo)
  updateTextInput(session, "Ritmo.medio", value = selected_run$Ritmo.medio)
  updateNumericInput(session,
                     "Cadencia.de.carrera.media",
                     value = selected_run$Cadencia.de.carrera.media)
  updateNumericInput(session,
                     "Longitud.media.de.zancada",
                     value = selected_run$Longitud.media.de.zancada)
})

# Update inputs when date is selected tabItem II
observeEvent(input$Fecha_i2, {
  selected_run_ <- df %>% filter(Fecha == as.POSIXct(input$Fecha_i2))
  
  updateTextInput(session, "calorias", value = selected_run_$calorias)
  updateTextInput(session,
                  "Frecuencia.cardiaca.media",
                  value = selected_run_$Frecuencia.cardiaca.media)
  updateTextInput(session, "TE.aeróbico", value = selected_run_$TE.aeróbico)
})

# Calculate total activities
total_activities <- nrow(df)

output$total_activities_box <- renderValueBox({
  valueBox(
    total_activities,
    "Total Activities",
    icon = icon("list", lib = "font-awesome"),
    color = "orange"
  )
})

# Calculate total distance
total_distance <- sum(df$Distancia)

# Render valueBox
output$total_distance_box <- renderValueBox({
  valueBox(
    total_distance,
    "Total distance traveled (Kms)",
    icon = icon("person-running", lib = "font-awesome"),
    color = "maroon"
  )
})

# Function to convert "hh:mm:ss" to hours
time_to_hours <- function(time) {
  time_as_posix <- as.POSIXct(time, format = "%H:%M:%S", tz = "UTC")
  total_hours <- as.numeric(format(time_as_posix, "%H")) +
    as.numeric(format(time_as_posix, "%M")) / 60 +
    as.numeric(format(time_as_posix, "%S")) / 3600
  return(total_hours)
}

# Calculate total time in hours
total_time_hours <- sum(sapply(df$Tiempo, time_to_hours))

# Render valueBox
output$total_time_box <- renderValueBox({
  valueBox(
    sprintf("%.2f", total_time_hours),
    "Total Time (hours)",
    icon = icon("clock", lib = "font-awesome")
  )
})

# Function to convert "mm:ss" to total seconds
pace_to_seconds <- function(Ritmo.medio) {
  pace_as_posix <-
    as.POSIXct(Ritmo.medio,
               format = "%M:%S",
               tz = "UTC",
               origin = "1970-01-01")
  if (is.na(pace_as_posix)) {
    return(NA)
  }
  total_seconds <- as.numeric(format(pace_as_posix, "%M")) * 60 +
    as.numeric(format(pace_as_posix, "%S"))
  return(total_seconds)
}

# Function to convert total seconds to "mm:ss" format
seconds_to_pace <- function(total_seconds) {
  pace_as_posix <-
    as.POSIXct(total_seconds, origin = "1970-01-01", tz = "UTC")
  pace <- strftime(pace_as_posix, format = "%M:%S")
  return(pace)
}

# Convert avg_pace to POSIXct
df$Ritmo.medio <- sapply(df$Ritmo.medio, pace_to_seconds)

# Function to calculate average pace in "mm:ss" format
calculate_average_pace <- function(paces) {
  # Remove NA values before calculating the mean
  paces <- paces[!is.na(paces)]
  
  if (length(paces) == 0) {
    return("N/A")
  }
  
  total_seconds <- mean(paces)
  average_pace <- seconds_to_pace(total_seconds)
  return(average_pace)
}

# Calculate average pace
#total_average_pace <- mean(df$Ritmo.medio)
total_average_pace <- calculate_average_pace(df$Ritmo.medio)

# Render valueBox
output$total_average_pace_box <- renderValueBox({
  valueBox(
    total_average_pace,
    "Average pace (pmm)",
    icon = icon("street-view", lib = "font-awesome"),
    color = "green"
  )
})

# Calculate average running cadence
total_average_running <-
  signif(mean(df$Cadencia.de.carrera.media), 4)

# Render valueBox
output$total_average_running_box <- renderValueBox({
  valueBox(
    total_average_running,
    "average running cadence (pmm)",
    icon = icon("gears", lib = "font-awesome"),
    color = "purple"
  )
})

# Calculate Average Stride Length
total_average_stride <-
  signif(mean(df$Longitud.media.de.zancada), 4)

# Render valueBox
output$total_average_stride_box <- renderValueBox({
  valueBox(
    total_average_stride,
    "Average Stride Length (pmm)",
    icon = icon("person-walking", lib = "font-awesome"),
    color = "olive"
  )
})

################################# Temperature #######################################

# Reactive expression to filter data based on selected date
filtered_data <- reactive({
  df %>%
    filter(Fecha == input$Fecha_i2)
})

# Reactive expression to reshape the data and calculate minimum and maximum temperature
min_max_temps <- reactive({
  filtered_data() %>%
    gather(key = "temperature_type",
           value = "temperature",
           Temperatura.mínima,
           Temperatura.máxima)
})

# Render the temperature plot
output$temperature_plot <- renderPlot({
  # Create a bar plot for minimum and maximum temperature
  ggplot(data = min_max_temps(),
         aes(x = temperature_type, y = temperature, fill = temperature_type)) +
    geom_bar(stat = "identity") +
    labs(title = "Minimum and Maximum Temperature",
         x = "Temperature Type",
         y = "Temperature Value") +
    scale_fill_manual(values = c("#97ea36", "#b4d081")) +
    theme_minimal()
})

################################### Heigth ##########################################

# Reactive expression to filter data based on selected date
filtered_data_height <- reactive({
  df %>%
    filter(Fecha == input$Fecha_i2)
})

# Reactive expression to reshape the data and calculate minimum and maximum height
min_max_heighs <- reactive({
  filtered_data_height() %>%
    gather(key = "height_type",
           value = "height",
           Altura.mínima,
           Altura.máxima)
})

# Render the height plot
output$height_plot <- renderPlot({
  # Create a bar plot for minimum and maximum height
  ggplot(data = min_max_heighs(), aes(x = height_type, y = height, fill = height_type)) +
    geom_bar(stat = "identity") +
    labs(title = "Minimum and Maximum Height",
         x = "Height Type",
         y = "Height Value") +
    scale_fill_manual(values = c("#c1440e", "#e97451")) +
    theme_minimal()
})

}
