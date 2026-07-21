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

## Requisitos

Paquetes en R (consolidado):

- dplyr
- janitor
- lubridate
- zoo
- glmnet
- randomForest
- xgboost
- forecast
- plotly
- tictoc


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
