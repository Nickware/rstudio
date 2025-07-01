# ---- Funciones Compartidas ----
library(rvest)
library(testthat)

# 1. Scraping (Ejemplo - adaptar a tu web real)
scrapear_baloto <- function(url = "https://www.resultadobaloto.com/resultados.php") {
  # (Implementación igual a tu versión anterior)
}

# 2. Cálculo de frecuencias
calcular_frecuencias <- function(datos) {
  datos %>%
    select(-Fecha) %>%
    pivot_longer(everything(), names_to = "Balota", values_to = "Numero") %>%
    count(Balota, Numero) %>%
    complete(Balota, Numero = 1:max(Numero), fill = list(n = 0))
}

# 3. Visualización
graficar_frecuencias <- function(frecuencias) {
  p_main <- frecuencias %>%
    filter(Balota != "SuperBalota") %>%
    ggplot(aes(x = Numero, y = n)) +
    geom_col(fill = "gold") +
    facet_wrap(~Balota, ncol = 2) +
    labs(title = "Frecuencia por Balota (1-5)")
  
  p_super <- frecuencias %>%
    filter(Balota == "SuperBalota") %>%
    ggplot(aes(x = Numero, y = n)) +
    geom_col(fill = "firebrick") +
    labs(title = "SuperBalota")
  
  plot_grid(p_main, p_super, ncol = 1, rel_heights = c(3, 1))
}

# 4. Validación estadística
validar_uniformidad <- function(frecuencias) {
  resultados <- frecuencias %>%
    group_by(Balota) %>%
    summarise(
      p_value = suppressWarnings(chisq.test(n)$p.value),
      .groups = "drop"
    )
  
  # Test unitario
  test_that("Test de Uniformidad", {
    expect_true(all(resultados$p_value > 0.05))
  })
  
  return(resultados)
}