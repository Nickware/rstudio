# R/schemas.R
# Definición de esquemas de datos para archivos Garmin
# Versión: 1.0
# Última actualización: Junio 2026

# Esquema de actividad individual (44 columnas)
individual_schema <- list(
  id_vuelta = "Vueltas",
  tiempo = "Tiempo",
  tiempo_acumulado = "Tiempo.acumulado",
  distancia = "Distancia",
  ritmo_medio = "Ritmo.medio",
  gap_medio = "GAP.medio",
  fc_media = "Frecuencia.cardiaca.media",
  fc_maxima = "FC.máxima",
  ascenso = "Ascenso.total",
  descenso = "Descenso.total",
  potencia_media = "Potencia.media",
  wkg_media = "Media.de.W.kg",
  potencia_maxima = "Potencia.máxima",
  wkg_maximo = "Máximo.de.W.kg",
  cadencia_media = "Cadencia.de.carrera.media",
  tiempo_contacto = "Tiempo.medio.de.contacto.con.el.suelo",
  equilibrio_tcs = "Equilibrio.de.TCS.medio",
  longitud_zancada = "Longitud.media.de.zancada",
  oscilacion_vertical = "Oscilación.vertical.media",
  relacion_vertical = "Relación.vertical.media",
  calorias = "Calorías",
  temperatura = "Temperatura.media",
  ritmo_optimo = "Ritmo.óptimo",
  cadencia_maxima = "Cadencia.de.carrera.máxima",
  tiempo_movimiento = "Tiempo.en.movimiento",
  ritmo_movimiento = "Ritmo.medio.en.movimiento",
  perdida_velocidad = "Pérdida.de.velocidad.de.paso.media",
  porcentaje_perdida = "Porcentaje.de.pérdida.de.velocidad.de.paso.media"
)

# Esquema de actividad colectiva (36 columnas)
colectivo_schema <- list(
  tipo = "Tipo.de.actividad",
  fecha = "Fecha",
  favorito = "Favorito",
  titulo = "Título",
  distancia = "Distancia",
  tiempo = "Tiempo",
  tiempo_movimiento = "Tiempo.en.movimiento",
  tiempo_transcurrido = "Tiempo.transcurrido",
  calorias = "Calorías",
  fc_media = "Frecuencia.cardiaca.media",
  fc_maxima = "FC.máxima",
  te_aerobico = "TE.aeróbico",
  cadencia_media = "Cadencia.de.carrera.media",
  cadencia_maxima = "Cadencia.de.carrera.máxima",
  ritmo_medio = "Ritmo.medio",
  ritmo_optimo = "Ritmo.óptimo",
  longitud_zancada = "Longitud.media.de.zancada",
  relacion_vertical = "Relación.vertical.media",
  oscilacion_vertical = "Oscilación.vertical.media",
  tiempo_contacto = "Tiempo.medio.de.contacto.con.el.suelo",
  equilibrio_tcs = "Equilibrio.medio.de.tiempo.de.contacto.con.el.suelo",
  ascenso = "Ascenso.total",
  descenso = "Descenso.total",
  altitud_min = "Altura.mínima",
  altitud_max = "Altura.máxima",
  temperatura_min = "Temperatura.mínima",
  temperatura_max = "Temperatura.máxima",
  tss = "Training.Stress.Score",
  pasos = "Pasos",
  vueltas = "Número.de.vueltas",
  mejor_vuelta = "Mejor.tiempo.de.vuelta",
  descompresion = "Descompresión"
)