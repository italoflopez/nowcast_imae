# Nowcasting del IMAE con selección de variables y modelos de aprendizaje automático

Este repositorio contiene el código y los datos utilizados para construir un sistema de **nowcasting del Índice Mensual de Actividad Económica (IMAE)** mediante técnicas de selección de variables, modelos econométricos tradicionales y algoritmos de aprendizaje automático utilizando feature engineering.

El objetivo es evaluar el desempeño predictivo de distintas metodologías utilizando un esquema de evaluación **pseudo-out-of-sample** cuando se realiza un feature engineering típico de series de tiempo.

---

## Estructura del repositorio

```text
.
├── data_tercer_blogpost.csv   # Base de datos con indicadores macroeconómicos mensuales
├── nowcast_imae_3.R           # Script principal de limpieza, transformación, modelado y evaluación
├── utils.R                    # Funciones auxiliares y carga de librerías
└── README.md
```

---

## Descripción de los archivos

### `data_tercer_blogpost.csv`

Contiene las series macroeconómicas mensuales utilizadas para la estimación del modelo.

Incluye variables relacionadas con:

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

---

### `utils.R`

Carga las librerías necesarias y define funciones auxiliares utilizadas durante el proceso de modelado.

#### Librerías principales

- Manipulación de datos: `dplyr`, `tidyr`, `janitor`, `data.table`
- Series de tiempo: `forecast`, `zoo`, `xts`, `lubridate`
- Machine Learning: `glmnet`, `randomForest`, `xgboost`, `caret`
- Visualización: `ggplot2`, `plotly`
- Utilidades: `tictoc`

#### Funciones incluidas

##### `gram_schmidt_forward()`

Implementa un algoritmo de selección secuencial de variables basado en ortogonalización mediante el procedimiento de Gram-Schmidt.

El algoritmo:

1. Ortogonaliza las variables candidatas.
2. Calcula la correlación con el residuo actual.
3. Selecciona la variable con mayor poder explicativo incremental.
4. Evalúa el incremento marginal del \(R^2\).
5. Finaliza cuando la ganancia marginal es inferior al umbral especificado.

##### `plot_regression_efficiency()`

Genera gráficos de dispersión entre valores observados y pronosticados, ajustando una regresión lineal para evaluar la eficiencia del pronóstico.

##### `forecast_diagnosis_test()`

Realiza pruebas de hipótesis conjuntas sobre eficiencia del pronóstico:

- Intercepto igual a cero.
- Pendiente igual a uno.

##### `cumsd()` y `cummean_na()`

Funciones auxiliares para el cálculo acumulado de estadísticas descriptivas.

---

### `nowcast_imae_3.R`

Script principal del proyecto.

Implementa todo el flujo de trabajo:

1. Carga de datos.
2. Limpieza.
3. Transformación de variables.
4. Selección de predictores.
5. Estimación de modelos.
6. Evaluación pseudo-out-of-sample.
7. Comparación de desempeño.

---

## Metodología

### 1. Carga de datos

Se cargan los datos desde:

```r
df_raw_data <- read.csv("data_tercer_blogpost.csv")
```

El análisis se restringe al período:

```text
2014–2025
```

---

### 2. Limpieza de datos

Las principales tareas de limpieza incluyen:

- Corrección de valores faltantes específicos.
- Creación de una variable de fecha mensual.
- Interpolación lineal de valores faltantes mediante `na.approx()`.
- Eliminación de variables con información redundante o baja disponibilidad.

Variables excluidas:

- `GasolinaRegular`
- `CONSUMO_TC`
- `LIMITE_TC`
- `ITBIS`
- `ITBIS_12m`

---

### 3. Transformación de variables

Se generan múltiples transformaciones para capturar la dinámica de corto y largo plazo de las series.

#### Variable objetivo

La variable dependiente es:

```math
IMAE_{yoy} = 100 \times [\log(IMAE_t) - \log(IMAE_{t-12})]
```

#### Variables explicativas

Para cada predictor se calculan:

- Variación interanual logarítmica:

```math
100 \times [\log(x_t) - \log(x_{t-12})]
```

- Variación mensual logarítmica:

```math
100 \times [\log(x_t) - \log(x_{t-1})]
```

- Suma móvil de tres meses de la variación mensual.

Además, se generan rezagos de una, dos y tres observaciones para variables seleccionadas.

---

### 4. Selección de variables

Se aplica el algoritmo `gram_schmidt_forward()` para identificar el subconjunto óptimo de predictores.

Criterio de selección:

```r
r2_threshold = 0.005
```

La selección se realiza únicamente sobre la muestra de entrenamiento.

---

### 5. Variables dummy

Se incorporan variables indicadoras para capturar los efectos estructurales asociados a la pandemia del COVID-19.

- `dummy_covid1`: marzo 2020 – febrero 2021.
- `dummy_covid2`: marzo 2021 – marzo 2022.

---

### 6. Evaluación pseudo-out-of-sample

La evaluación se realiza utilizando una ventana expansiva.

Proceso:

1. Se entrena el modelo con las primeras observaciones disponibles.
2. Se genera un pronóstico a un paso adelante.
3. Se incorpora la nueva observación al conjunto de entrenamiento.
4. Se repite el procedimiento hasta el final de la muestra.

Configuración:

```r
start_window <- 30
```

---

## Modelos evaluados

El repositorio compara múltiples enfoques de pronóstico.

### 1. Regresión lineal con variables seleccionadas por Gram-Schmidt

Modelo de referencia basado en mínimos cuadrados ordinarios.

### 2. Ridge Regression

Regularización \(L_2\).

```r
cv.glmnet(x_train, y_train, alpha = 0)
```

### 3. LASSO

Regularización \(L_1\).

```r
cv.glmnet(x_train, y_train, alpha = 1)
```

### 4. Elastic Net

Combinación de penalizaciones \(L_1\) y \(L_2\).

```r
cv.glmnet(x_train, y_train, alpha = 0.5)
```

### 5. LASSO + ARIMA sobre residuos

Procedimiento híbrido:

1. Estimación mediante LASSO.
2. Modelado ARIMA de los residuos.
3. Corrección del pronóstico con la predicción del componente residual.

### 6. SARIMA univariado

Modelo autoregresivo estacional estimado únicamente sobre la serie objetivo.

### 7. Random Forest

Configuración utilizada:

```r
randomForest(
  imae_yoy_log ~ . - ano - mes - date,
  data = train_data_rf,
  ntree = 500
)
```

### 8. XGBoost

Configuración utilizada:

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

### 9. Elastic Net de alta dimensión

Modelo estimado utilizando el conjunto completo de variables disponibles.

---

## Métricas de evaluación

El desempeño predictivo se evalúa mediante la raíz del error cuadrático medio (RMSE).

```math
RMSE = \sqrt{\frac{1}{n}\sum_{t=1}^{n}(y_t-\hat{y}_t)^2}
```

Las métricas se calculan para:

- Muestra completa.
- Período pre-COVID.
- Período post-COVID.

---

## Visualización de resultados

El script genera:

- Comparaciones entre valores observados y pronosticados.
- Gráficos interactivos con `plotly`.
- Regresiones de eficiencia del pronóstico.

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

Instale las dependencias antes de ejecutar el proyecto.

```r
install.packages(c(
  "tidyverse",
  "data.table",
  "janitor",
  "lubridate",
  "zoo",
  "xts",
  "forecast",
  "glmnet",
  "randomForest",
  "xgboost",
  "caret",
  "plotly",
  "openxlsx",
  "readxl",
  "tictoc",
  "leaps",
  "roll"
))
```

Dependencias adicionales:

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
```

Acceda al directorio:

```bash
cd nombre-repositorio
```

Abra el script principal en R o RStudio y ejecute:

```r
source("nowcast_imae_3.R")
```

---

## Flujo de trabajo resumido

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

La ejecución del script producirá:

- Pronósticos pseudo-out-of-sample.
- Errores de predicción.
- Comparaciones de RMSE entre modelos.
- Gráficos interactivos de desempeño.
- Análisis de eficiencia de pronóstico.

---

## Referencia

Si utiliza este código en investigación aplicada o trabajos derivados, cite el blogpost correspondiente y este repositorio.
