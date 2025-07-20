library(rvest)
library(tidyverse)

obtener_datos_reales <- function() {
  tryCatch({
    url <- "https://www.resultadobaloto.com/resultados.php"
    tabla <- read_html(url) %>% 
      html_nodes("table") %>% 
      .[[2]] %>% 
      html_table()
    
    # Limpieza robusta conservando la fecha
    tabla_limpia <- tabla %>%
      rename(
        Fecha = 1,  # Usar posición si el nombre falla
        Combinacion = "Combinación Ganadora",
        SuperBalota = "Super Balota."
      ) %>%
      mutate(
        Fecha = as.Date(Fecha, format = "%d/%m/%Y"),  # Ajusta el formato
        Combinacion = gsub(" ", "", Combinacion)
      ) %>%
      separate(
        Combinacion,
        into = paste0("Balota0", 1:5),
        sep = "\\|",
        convert = TRUE
      ) %>%
      select(Fecha, everything())  # Asegurar que Fecha esté primera
    
    return(tabla_limpia)
  }, error = function(e) {
    stop(paste("Error en scraping:", e$message))
  })
}