# Nowcasting del IMAE: Desarrollo Iterativo de Modelos Econométricos y de Aprendizaje Automático

## Descripción general

Este repositorio documenta el desarrollo progresivo de un sistema de **nowcasting del Indicador Mensual de Actividad Económica (IMAE)**, cuyo objetivo es estimar el crecimiento económico en tiempo real antes de la publicación oficial de los datos.

El proyecto está estructurado como un proceso iterativo en **tres etapas**:

- **Primera iteración**: construcción de un marco base con modelos econométricos tradicionales (OLS)
- **Segunda iteración**: extensión del marco base mediante técnicas de regularización y selección automática de variables
- **Tercera iteración**: ampliación hacia un marco comparativo con feature engineering exhaustivo, selección de variables y modelos de aprendizaje automático

Este enfoque permite evidenciar cómo evoluciona un sistema de nowcasting al incorporar mayor sofisticación metodológica y un conjunto más amplio de información.

---

## Objetivos

- Construir un sistema de nowcasting paso a paso
- Evaluar el aporte incremental de distintas metodologías
- Identificar variables con mayor poder predictivo sobre el IMAE
- Comparar modelos simples vs. modelos regularizados vs. modelos de aprendizaje automático
- Analizar la estabilidad del desempeño en distintos períodos (pre y post COVID)
- Determinar si la no linealidad (Random Forest, XGBoost) aporta valor predictivo frente a enfoques lineales regularizados

---

## Arquitectura del proyecto

El repositorio se divide en tres componentes principales:

### 🔹 Iteración 1: Enfoque econométrico base (`nowcast_imae_1.R`)
**Carpeta**: `1_naive_vs_modernos`

**Blogpost**: https://medium.com/@SB-ESTUDIOS/proyectando-el-nivel-de-actividad-económica-el-caso-del-nowcast-del-imae-30abe4ae0589

Esta primera versión establece las bases del sistema de nowcasting mediante herramientas econométricas estándar.

**Características principales:**

- Modelos lineales (OLS)
- Inclusión de rezagos del IMAE
- Incorporación de variables contemporáneas (ej. consumo, turismo)
- Construcción manual de especificaciones
- Evaluación mediante RMSE
- Análisis exploratorio completo

**Rol dentro del proyecto:**

- Define el benchmark inicial
- Permite entender la dinámica del IMAE
- Proporciona una referencia para comparar mejoras posteriores

---

### 🔹 Iteración 2: Modelos avanzados (`nowcast_imae_2.R` + `gram_schmidt_forward.R`)
**Carpeta**: `2_shrinkage_gram_schmidt`

**Blogpost**: https://medium.com/@SB-ESTUDIOS/mejora-de-predicci%C3%B3n-en-un-entorno-de-alta-dimensi%C3%B3n-el-shrinkage-y-las-metodolog%C3%ADas-de-selecci%C3%B3n-943f023c0289

La segunda iteración amplía el enfoque inicial incorporando técnicas modernas de modelación.

**Mejoras introducidas:**

- Ridge Regression (`glmnet`) para mitigar sobreajuste
- Selección automática de variables (Gram-Schmidt Forward Selection)
- Evaluación más sistemática de múltiples modelos
- Manejo de mayor dimensionalidad en variables explicativas

**Características principales:**

- Modelos autorregresivos regularizados
- Modelos con múltiples combinaciones de variables macroeconómicas
- Procedimientos automáticos de selección de variables
- Comparación estructurada de desempeño

**Rol dentro del proyecto:**

- Mejora la capacidad predictiva
- Reduce problemas de colinealidad
- Permite escalar el sistema con más variables
- Representa una versión más robusta del nowcasting

---

### 🔹 Iteración 3: Selección de variables y modelos de aprendizaje automático (`nowcast_imae_3.R` + `utils.R`)
**Carpeta**: `3_feature_engineering`

La tercera iteración amplía el marco anterior incorporando feature engineering más exhaustivo y un conjunto amplio de modelos de aprendizaje automático, evaluados bajo un esquema pseudo-out-of-sample.

**Mejoras introducidas:**

- Feature engineering ampliado (variación interanual, mensual, suma móvil y rezagos)
- Selección automática de variables mediante `gram_schmidt_forward()`
- Nuevos modelos de regularización: LASSO y Elastic Net
- Modelo híbrido LASSO + ARIMA y modelo SARIMA univariado
- Modelos no lineales: Random Forest y XGBoost

**Rol dentro del proyecto:**

- Representa la versión más completa y sofisticada del sistema de nowcasting
- Evalúa si el aprendizaje automático supera a los enfoques econométricos regularizados
- Cierra el ciclo iterativo: benchmark simple → regularización y selección de variables → marco comparativo amplio con ML

---

## Estructura del repositorio (Iteración 3)

```text
.
├── data_tercer_blogpost.csv   # Base de datos con indicadores macroeconómicos mensuales
├── nowcast_imae_3.R           # Script principal de limpieza, transformación, modelado y evaluación
├── utils.R                    # Funciones auxiliares y carga de librerías
└── README.md
```

### `data_tercer_blogpost.csv`

Contiene las series macroeconómicas mensuales utilizadas para la estimación del modelo, incluyendo variables relacionadas con:

- Actividad económica
- Crédito
- Turismo
- Mercado laboral
- Tasas de interés
- Liquidez monetaria
- Remesas
- Indicadores financieros
- Variables externas

La variable objetivo es:

- `IMAE`: Índice Mensual de Actividad Económica.

### `utils.R`

Carga las librerías necesarias y define funciones auxiliares utilizadas durante el proceso de modelado.

**Librerías principales:**

- Manipulación de datos: `dplyr`, `tidyr`, `janitor`, `data.table`
- Series de tiempo: `forecast`, `zoo`, `xts`, `lubridate`
- Machine Learning: `glmnet`, `randomForest`, `xgboost`, `caret`
- Visualización: `ggplot2`, `plotly`
- Utilidades: `tictoc`

**Funciones incluidas:**

- **`gram_schmidt_forward()`**: implementa un algoritmo de selección secuencial de variables basado en ortogonalización mediante el procedimiento de Gram-Schmidt. El algoritmo ortogonaliza las variables candidatas, calcula la correlación con el residuo actual, selecciona la variable con mayor poder explicativo incremental, evalúa el incremento marginal del R², y finaliza cuando la ganancia marginal es inferior al umbral especificado.
- **`plot_regression_efficiency()`**: genera gráficos de dispersión entre valores observados y pronosticados, ajustando una regresión lineal para evaluar la eficiencia del pronóstico.
- **`forecast_diagnosis_test()`**: realiza pruebas de hipótesis conjuntas sobre eficiencia del pronóstico (intercepto igual a cero, pendiente igual a uno).
- **`cumsd()` y `cummean_na()`**: funciones auxiliares para el cálculo acumulado de estadísticas descriptivas.

### `nowcast_imae_3.R`

Script principal del proyecto. Implementa todo el flujo de trabajo: carga de datos, limpieza, transformación de variables, selección de predictores, estimación de modelos, evaluación pseudo-out-of-sample y comparación de desempeño.

---

## Enfoque metodológico común (las tres iteraciones)

### Transformación de variables

```math
YoY = (\log(x_t) - \log(x_{t-12})) * 100
```

### Ingeniería de variables

- Rezagos del IMAE
- Variables contemporáneas
- Dummies para:
  - COVID-19 (fase 1 y fase 2 en Iteración 3)
  - Período de rebote

### Evaluación en tiempo real

- Simulación mediante ventanas expansivas
- Estimación con información disponible en cada período

### Métrica principal

```math
RMSE = \sqrt{\frac{1}{n}\sum_{t=1}^{n}(y_t-\hat{y}_t)^2}
```

Evaluado en:

- Muestra completa
- Período pre-COVID
- Período post-COVID

---

## Metodología detallada — Iteración 3

### 1. Carga de datos

```r
df_raw_data <- read.csv("data_tercer_blogpost.csv")
```

El análisis se restringe al período **2014–2025**.

### 2. Limpieza de datos

- Corrección de valores faltantes específicos
- Creación de una variable de fecha mensual
- Interpolación lineal de valores faltantes mediante `na.approx()`
- Eliminación de variables con información redundante o baja disponibilidad

Variables excluidas: `GasolinaRegular`, `CONSUMO_TC`, `LIMITE_TC`, `ITBIS`, `ITBIS_12m`

### 3. Transformación de variables

**Variable objetivo:**

```math
IMAE_{yoy} = 100 \times [\log(IMAE_t) - \log(IMAE_{t-12})]
```

**Variables explicativas** — para cada predictor se calculan:

- Variación interanual logarítmica: `100 × [log(x_t) - log(x_{t-12})]`
- Variación mensual logarítmica: `100 × [log(x_t) - log(x_{t-1})]`
- Suma móvil de tres meses de la variación mensual

Además, se generan rezagos de una, dos y tres observaciones para variables seleccionadas.

### 4. Selección de variables

Se aplica el algoritmo `gram_schmidt_forward()` para identificar el subconjunto óptimo de predictores.

```r
r2_threshold = 0.005
```

La selección se realiza únicamente sobre la muestra de entrenamiento.

### 5. Variables dummy

- `dummy_covid1`: marzo 2020 – febrero 2021
- `dummy_covid2`: marzo 2021 – marzo 2022

### 6. Evaluación pseudo-out-of-sample

Ventana expansiva:

1. Se entrena el modelo con las primeras observaciones disponibles
2. Se genera un pronóstico a un paso adelante
3. Se incorpora la nueva observación al conjunto de entrenamiento
4. Se repite el procedimiento hasta el final de la muestra

```r
start_window <- 30
```

---

## Modelos considerados (consolidado — las tres iteraciones)

- Modelo naive
- Modelo autorregresivo (OLS)
- Modelos con variables adicionales (consumo, turismo, etc.)
- Modelo Ridge autorregresivo
- Modelos Ridge ampliados
- Modelo con variables seleccionadas automáticamente (Gram-Schmidt)
- Regresión lineal con selección Gram-Schmidt (Iteración 3)
- LASSO
- Elastic Net
- LASSO + ARIMA sobre residuos
- SARIMA univariado
- Random Forest
- XGBoost
- Elastic Net de alta dimensión

### Detalle de modelos de Iteración 3

**1. Regresión lineal con variables seleccionadas por Gram-Schmidt** — modelo de referencia basado en mínimos cuadrados ordinarios.

**2. Ridge Regression** (regularización L2):
```r
cv.glmnet(x_train, y_train, alpha = 0)
```

**3. LASSO** (regularización L1):
```r
cv.glmnet(x_train, y_train, alpha = 1)
```

**4. Elastic Net** (combinación L1/L2):
```r
cv.glmnet(x_train, y_train, alpha = 0.5)
```

**5. LASSO + ARIMA sobre residuos** — procedimiento híbrido: estimación mediante LASSO, modelado ARIMA de los residuos, y corrección del pronóstico con la predicción del componente residual.

**6. SARIMA univariado** — modelo autoregresivo estacional estimado únicamente sobre la serie objetivo.

**7. Random Forest**:
```r
randomForest(
  imae_yoy_log ~ . - ano - mes - date,
  data = train_data_rf,
  ntree = 500
)
```

**8. XGBoost**:
```r
params <- list(
  objective = "reg:squarederror",
  max_depth = 4,
  eta = 0.1,
  subsample = 0.8,
  colsample_bytree = 0.8
)
```
El número óptimo de iteraciones se selecciona mediante validación cruzada.

**9. Elastic Net de alta dimensión** — modelo estimado utilizando el conjunto completo de variables disponibles.

---

## Datos requeridos

### Variables temporales

- ANO
- MES

### Variable objetivo

- IMAE

### Variables explicativas (ejemplos)

- Consumo con tarjetas
- Ocupación hotelera
- Inflación
- Ventas
- Crédito
- Mercado laboral, tasas de interés, liquidez monetaria, remesas y variables externas (Iteración 3)

---

## Visualización de resultados (Iteración 3)

El script genera:

- Comparaciones entre valores observados y pronosticados
- Gráficos interactivos con `plotly`
- Regresiones de eficiencia del pronóstico

Ejemplo:

```r
plot_ly(
  df_forecast_data %>%
    filter(date >= as.Date("2022-03-01")),
  x = ~date
) %>%
  add_lines(y = ~imae_yoy_log, name = "IMAE") %>%
  add_lines(
    y = ~nowcast_big_gram_schmidt_shrinkage_beginning_of_the_month,
    name = "Predicción"
  )
```

---

## Requisitos

Paquetes en R (consolidado):

```r
install.packages(c(
  "tidyverse",
  "dplyr",
  "data.table",
  "janitor",
  "zoo",
  "xts",
  "lubridate",
  "plotly",
  "forecast",
  "tseries",
  "glmnet",
  "randomForest",
  "xgboost",
  "caret",
  "openxlsx",
  "readxl",
  "modelsummary",
  "tictoc",
  "leaps",
  "roll"
))
```

Dependencias adicionales (Iteración 3):

- `ROracle`
- `DBI`
- `keyring`
- `rugarch`
- `timeSeries`

> **Nota:** algunas librerías pueden requerir configuraciones específicas del sistema operativo o instalaciones adicionales.

---

## Ejecución

Clone el repositorio:

```bash
git clone https://github.com/usuario/nombre-repositorio.git
cd nombre-repositorio
```

Ejecute cada iteración desde R o RStudio:

```r
# Iteración 1
source("nowcast_imae_1.R")

# Iteración 2
source("nowcast_imae_2.R")

# Iteración 3
source("nowcast_imae_3.R")
```

---

## Flujo general del proceso (Iteración 3)

```text
Datos crudos
      │
      ▼
Limpieza e interpolación
      │
      ▼
Transformaciones logarítmicas
      │
      ▼
Creación de rezagos
      │
      ▼
Selección de variables (Gram-Schmidt)
      │
      ▼
Estimación de modelos
      │
      ▼
Pseudo-out-of-sample
      │
      ▼
Cálculo de RMSE
      │
      ▼
Visualización y comparación
```

---

## Resultados esperados

- Pronósticos pseudo-out-of-sample
- Errores de predicción
- Comparaciones de RMSE entre modelos
- Gráficos interactivos de desempeño
- Análisis de eficiencia de pronóstico

---

## Interpretación y valor del enfoque iterativo

El diseño en tres iteraciones permite:

- Entender cómo un modelo base puede ser mejorado progresivamente
- Medir el valor de la regularización y la selección automática de variables (Iteración 2)
- Evaluar si técnicas de machine learning no lineales (Random Forest, XGBoost) aportan poder predictivo adicional frente a modelos lineales regularizados (Iteración 3)
- Contrastar enfoques híbridos (LASSO + ARIMA) contra modelos univariados puros (SARIMA)
- Evaluar el trade-off entre simplicidad, interpretabilidad y capacidad predictiva
- Construir un sistema de nowcasting robusto, escalable y comparativamente validado

---

## Conclusión

Este repositorio documenta el proceso de construcción de un sistema predictivo en tres etapas:

> Modelos econométricos simples → Modelos regularizados con selección de variables → Marco comparativo amplio con selección automática, modelos econométricos avanzados y aprendizaje automático

El resultado es un marco práctico, replicable y extensible para el monitoreo en tiempo real de la actividad económica, que evoluciona desde un benchmark simple hasta un sistema robusto capaz de comparar objetivamente enfoques lineales, regularizados e híbridos con modelos de machine learning.

---

## Referencia

Si utiliza este código en investigación aplicada o trabajos derivados, cite el blogpost correspondiente y este repositorio.
