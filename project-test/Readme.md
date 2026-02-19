# Baloto

Baloto es la lotería más popular de Colombia, un juego de azar tipo loto administrado por Coljuegos que ofrece premios multimillonarios acumulados. [baloto](https://baloto.com/que-es-baloto)

## Cómo se juega

- **Formato actual (desde 2025):** Eliges **5 números principales del 1 al 43** + **1 Superbalota del 1 al 16**. [es.scribd](https://es.scribd.com/document/851924091/Baloto)
- **Costo:** $6.000 COP por apuesta simple (incluye Baloto + Revancha automática). [mundovideo.com](https://www.mundovideo.com.co/coljuegoseice/coljuegos-aprueba-cambios-al-reglamento-de-baloto-nuevos-precios-sorteos-y-premios/)
- **Sorteos:** **Lunes, miércoles y sábados** a las 10:00 p.m., transmitidos en vivo. [deportivas.com](https://deportivas.com.co/plan-de-premios-del-baloto-cuanto-paga-por-numeros-acertados)
- **Opciones adicionales:** Revancha (mismo sorteo, premio separado de $2.000 millones iniciales) y Multiplicador opcional. [loteriasdehoy](https://loteriasdehoy.co/baloto)

## Plan de premios (aproximado, variable)

| Aciertos          | Premio típico (millones COP) |
|-------------------|------------------------------|
| 5 + Superbalota   | Acumulado ($4.300M inicial, crece)  [baloto](https://baloto.com/que-es-baloto) |
| 5 + 0             | $30-50M  [resultadobaloto](https://www.resultadobaloto.com/resultados.php)     |
| 4 + Superbalota   | $1-2M  [loteriasdehoy](https://loteriasdehoy.co/baloto)               |
| 4 + 0             | $100-200K                    |
| 3 + Superbalota   | $50-60K                      |
| 3 + 0             | $10K                         |
| 2 + Superbalota   | $12K                         |
| 1/0 + Superbalota | $6K                          |

- **Probabilidad premio mayor:** 1 en 15.401.568 combinaciones. [occidente](https://occidente.co/colombia/que-probabilidad-hay-de-ganarse-el-baloto/)
- **Pago:** En puntos autorizados (hasta $10M) o bancos/Coljuegos (premios mayores); requieren identificación. [baloto](https://baloto.com/pago-de-premios)

## Resultados recientes (febrero 2026)

El jackpot principal sigue **acumulándose** (sin ganadores recientes del 5+1). [resultadobaloto](https://www.resultadobaloto.com/resultados.php)

| Fecha       | Números principales | Superbalota | Notas (Revancha) |
|-------------|---------------------|-------------|------------------|
| 16/02/2026 | 09-18-21-22-42     | 14         | Acumulado $22.400M  [mundonets](https://www.mundonets.com/baloto/) |
| 14/02/2026 | 15-21-29-34-35     | 06         | 1 ganador 5+0 ($46M)  [resultadobaloto](https://www.resultadobaloto.com/resultados.php) |
| 11/02/2026 | 09-14-30-36-42     | 06         | Acumulado        |
| 09/02/2026 | 11-17-20-36-38     | 14         | 1 ganador 5+0 ($17M) |

Datos completos en baloto.com/resultados. [baloto](https://baloto.com/resultados)

## Dónde jugar

- **Puntos físicos:** Más de 10.000 puntos autorizados en Colombia.  
- **En línea:** Plataformas autorizadas como baloto.com o apps oficiales. [baloto](https://baloto.com)
- **Edad mínima:** 18 años. [coljuegos.gov](https://www.coljuegos.gov.co/publicaciones/300629/baloto/)

Baloto genera fondos para programas sociales; recuerda que es entretenimiento, no inversión (valor esperado negativo). [focusgn](https://focusgn.com/latinoamerica/como-se-juega-el-baloto)

# Proyecto Baloto Analyzer

Esta aplicación busca analizar los sorteos, simular sorteos y predecir conjuntos de números de Baloto. 

##  Estado Actual: FASE 1 COMPLETADA

### Arquitectura Implementada

#### Módulos Principales:
1. Base de datos - Fuente única de verdad
2. Análisis univariado - Estadísticas individuales
3. Análisis multivariado - Relaciones entre variables
4. Validación estadística - Pruebas de hipótesis

#### Tecnología:
- **Frontend**: Shiny Dashboard + Plotly + DT
- **Backend**: R + Tidyverse
- **Datos**: Web scraping en tiempo real
- **Visualización**: Gráficos interactivos

---

##  FUNCIONALIDADES IMPLEMENTADAS

### 1.  BASE DE DATOS
-  **Scraping automático** desde resultadobaloto.com
-  **Limpieza y validación** de datos
-  **Tabla interactiva** con todos los sorteos históricos
-  **Actualización manual** con un botón

### 2.  ANÁLISIS UNIVARIADO

#### Distribuciones:
-  **Histogramas interactivos** por balota
-  **Diagramas de caja** por posición
-  **Estadísticos descriptivos** completos
-  **Frecuencias globales** tabuladas

#### Tendencias:
-  **Series temporales** de promedios acumulados
-  **Medias móviles** configurables
-  **Visualización comparativa** entre balotas

### 3.  ANÁLISIS MULTIVARIADO

#### Por Posición:
-  **Heatmap interactivo** frecuencias vs posición
-  **Tabla de contingencia** detallada
-  **Histogramas comparativos** entre posiciones
-  **Exportación** a CSV

#### Correlaciones:
-  *En desarrollo* - Matriz de correlación
-  *En desarrollo* - Autocorrelación

### 4.  VALIDACIÓN ESTADÍSTICA
-  *En desarrollo* - Pruebas de uniformidad
-  *En desarrollo* - Test de aleatoriedad

---

##  EXPERIENCIA DE USUARIO

### Interfaz:
-  **Menú jerárquico** organizado por módulos
-  **Navegación intuitiva** entre pestañas
-  **Controles contextuales** (solo donde son relevantes)
-  **Responsive design** adaptable a diferentes pantallas

### Interactividad:
-  **Tooltips informativos** en todos los gráficos
-  **Filtros dinámicos** y selectores
-  **Zoom y pan** en series temporales
-  **Descarga de datos** en formatos estándar

---

##  CAPACIDADES ANALÍTICAS ACTUALES

### Detección de Patrones:
```r
# Ejemplo de insights que puede generar:
- "El número 7 aparece 12 veces en Balota 1 (frecuencia atípica)"
- "SuperBalota muestra distribución uniforme (p-value > 0.05)"
- "Tendencia alcista en Balota 3 últimos 20 sorteos"
```

### Validación de Supuestos:
- Distribución esperada vs observada
- Independencia entre sorteos
- Uniformidad por posición

### Visualización Profesional:
- Heatmaps con escala de colores
- Boxplots con medidas de dispersión
- Series temporales con rangeslider

---

##  LOGROS TÉCNICOS

### Código:
-  **Arquitectura modular** y escalable
-  **Manejo robusto** de errores
-  **Funciones puras** y reactivas
-  **Sin dependencias** externas problemáticas

### Datos:
-  **Pipeline automatizado** de adquisición
-  **Transformaciones** eficientes con dplyr
-  **Estructura consistente** en todos los análisis

### Performance:
-  **Carga rápida** de visualizaciones
-  **Interactividad** sin lag
-  **Manejo eficiente** de datos en memoria

---

##  PRÓXIMOS PASOS NATURALES

### Corto Plazo (Fase 1.5):
1. **Completar módulo de Correlaciones**
2. **Implementar pruebas estadísticas** de uniformidad
3. **Añadir números "calientes/fríos"**

### Mediano Plazo (Fase 2):
1. **Módulo de Simulación** de sorteos
2. **Análisis de números atrasados**
3. **Sistema de alertas** automáticas

### Largo Plazo (Fase 3):
1. **Modelos predictivos** básicos
2. **Análisis de clusters** de números
3. **Dashboard ejecutivo** con KPIs

---

##  VALOR AGREGADO ACTUAL

### Para Investigadores:
- Herramienta completa de análisis exploratorio
- Visualizaciones listas para publicaciones
- Datos actualizados automáticamente

### Para Usuarios Generales:
- Interfaz intuitiva sin necesidad de código
- Análisis profundos con un clic
- Transparencia total en los métodos

### Para Desarrolladores:
- Código bien estructurado y documentado
- Fácil de extender y mantener
- Ejemplo de mejores prácticas en Shiny

---

##  CONCLUSIÓN

**Se busca construir una aplicación de análisis de datos profesional** que:

-  **Automatiza** la recolección y limpieza de datos
-  **Visualiza** patrones complejos de manera intuitiva  
-  **Valida** supuestos estadísticos robustamente
-  **Escala** fácilmente para nuevos análisis
-  **Comunica** insights de manera efectiva
