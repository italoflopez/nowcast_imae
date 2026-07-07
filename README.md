# Nowcasting del IMAE: de Modelos Lineales a Machine Learning

## Descripción general

Este repositorio/documentación consolida una serie de tres blogposts que desarrollan progresivamente un sistema de **nowcasting del Indicador Mensual de Actividad Económica (IMAE)**.

El objetivo central es **estimar el crecimiento económico en tiempo real**, utilizando información disponible con distintos rezagos, y evaluar cómo diferentes metodologías incrementan la capacidad predictiva del modelo.

A lo largo de las tres iteraciones se construye una narrativa metodológica que avanza desde:

1. Modelos econométricos básicos  
2. Modelos con regularización y selección de variables  
3. Modelos de aprendizaje automático  

---

## Objetivo del proyecto

Desarrollar y comparar distintos enfoques de nowcasting que permitan responder:

> ¿Qué información y qué metodología permiten predecir mejor la evolución del IMAE en tiempo real?

---

## Evolución metodológica

### Iteración 1: Modelos econométricos básicos

- Transformaciones interanuales (YoY)
- Modelos autorregresivos
- Variables contemporáneas
- OLS y ventana expansiva

### Iteración 2: Regularización y selección

- Ridge Regression
- Gram-Schmidt Forward Selection
- Comparación de modelos

### Iteración 3: Machine Learning

- Feature engineering
- LASSO, Elastic Net
- Random Forest, XGBoost
- Modelos híbridos

---

## Metodología

- Transformaciones en logaritmos
- Creación de rezagos
- Variables dummy para COVID
- Evaluación pseudo-out-of-sample

RMSE como métrica principal:

RMSE = sqrt(mean((y - y_hat)^2))

---

## Flujo de trabajo

Datos → Limpieza → Transformación → Features → Modelos → Evaluación → Comparación

---

## Conclusión

- Modelos simples siguen siendo competitivos
- Regularización mejora robustez
- Machine learning aporta mejoras en ciertos contextos
- Evaluación en tiempo real es clave
