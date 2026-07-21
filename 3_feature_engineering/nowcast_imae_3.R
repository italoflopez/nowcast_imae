source("./utils.R")


###Extrayendo la data
df_raw_data <- read.csv("data_tercer_blogpost.csv")


df_raw_data <- df_raw_data%>%dplyr::filter(ANO>=2014,ANO<=2025)

###Limpiando la data
df_untransformed_data_clean <- df_raw_data %>%
  mutate(CONSUMO_TC = ifelse(ANO == 2024 & MES == 5, NA, CONSUMO_TC))


df_untransformed_data_clean <- df_untransformed_data_clean %>%
  mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
  arrange(date) %>%
  mutate(CONSUMO_TC = na.approx(CONSUMO_TC, x = date, maxgap = 2, na.rm = FALSE),
         MH10A_INTERBANCARIA = na.approx(MH10A_INTERBANCARIA, x = date, maxgap = 2, na.rm = FALSE)
         ,
         MH10A= na.approx(MH10A, x = date, maxgap = 2, na.rm = FALSE)
  )%>%
  select(-date)



df_untransformed_data_clean <-df_untransformed_data_clean%>%select(
  -c(GasolinaRegular,CONSUMO_TC,LIMITE_TC,ITBIS,ITBIS_12m)
)


###Transformando la data
df_transformed_data <- df_untransformed_data_clean %>%
  arrange(ANO, MES) %>%
  mutate(lag_IMAE = dplyr::lag(IMAE, 1),
         IMAE_yoy_log=(log(IMAE)-log(dplyr::lag(IMAE,12)))*100)

vars <- df_transformed_data %>%
  select(-c(ANO, MES, OCUPACION_HOT, IPC_VAR, `Ratio_M3.M1`,
            RATIO_INCUMPLIMIENTO, TIPM_INTERBANCARIA,
            MH10A_INTERBANCARIA, MH10A,
            NET_INTEREST_INCOME_VAR, GROSS_CREDIT_INCOME_VAR,`EMBI.RD`,IMAE,IMAE_yoy_log)) %>%
  names()

df_transformed_data <- df_transformed_data %>%
  arrange(ANO, MES) %>%
  dplyr::mutate(
    dplyr::across(
      dplyr::all_of(vars),
      ~ (log(.x) - log(dplyr::lag(.x, 12))) * 100,
      .names = "{.col}_yoy_log"
    ),
    dplyr::across(
      dplyr::all_of(vars),
      ~ (log(.x) - log(dplyr::lag(.x, 1))) * 100,
      .names = "{.col}_mom_log"
    )
  )



df_transformed_data <- df_transformed_data %>%
  dplyr::mutate(
    dplyr::across(
      ends_with("mom_log"),
      ~ rollapply(.x, width = 3, FUN = sum, align = "right", fill = NA, na.rm = FALSE),
      .names = "{.col}_roll3"
    )
  )



df_transformed_data <- df_transformed_data %>%
  arrange(ANO, MES) %>%
  dplyr::mutate(
    dplyr::across(
      c(OCUPACION_HOT, IPC_VAR, `Ratio_M3.M1`,
        RATIO_INCUMPLIMIENTO, TIPM_INTERBANCARIA,
        MH10A_INTERBANCARIA, MH10A,
        NET_INTEREST_INCOME_VAR, GROSS_CREDIT_INCOME_VAR,
        ends_with("mom_log")
      ),
      list(
        lag1 = ~ dplyr::lag(.x, 1),
        lag2 = ~ dplyr::lag(.x, 2),
        lag3 = ~ dplyr::lag(.x, 3)
      ),
      .names = "{.col}_{.fn}"
    )
  )



df_forecast_data <- df_transformed_data%>%
  select(-c(ICDV,M1,IMAE,
            M2,Remesas,Reservas,`TC.venta`,Turistas,COTIZANTES,CREDITO.MN,lag_IMAE))


df_forecast_data <-df_forecast_data[complete.cases(df_forecast_data),]




x_vars <- df_forecast_data %>%
  select(-c(ANO,MES,IMAE_yoy_log)) %>%
  names()


result <- gram_schmidt_forward(
  data = df_forecast_data%>%
    mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
    dplyr::filter(date<as.Date("2025-12-01")),
  y_var = "IMAE_yoy_log",
  x_vars = x_vars,
  r2_threshold = 0.005
)

result$selected_variables




df_forecast_data <- df_forecast_data %>%
  mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
  mutate(
    dummy_covid1 = if_else(date >= as.Date("2020-03-01") &
                             date <= as.Date("2021-02-01"), 1, 0),
    
    dummy_covid2 = if_else(date >= as.Date("2021-03-01") &
                             date <= as.Date("2022-03-01"), 1, 0)
  )%>%select(-date)




###Preparando data frame para pseudo-out-of-sample
df_forecast_data <- janitor::clean_names(df_forecast_data)



df_forecast_data <- df_forecast_data %>%
  mutate(date = make_date(ano, mes, 1))


df_forecast_data$nowcast_big_gram_schmidt_beginning_of_the_month<- NA

df_forecast_data$nowcast_big_gram_schmidt_shrinkage_beginning_of_the_month<- NA

df_forecast_data$nowcast_big_gram_schmidt_lasso_beginning_of_the_month<- NA

df_forecast_data$nowcast_big_gram_schmidt_elastic_net_beginning_of_the_month<- NA

df_forecast_data$nowcast_big_random_forest_beginning_of_the_month<- NA

df_forecast_data$nowcast_big_gram_schmidt_xgboost_beginning_of_the_month<- NA

df_forecast_data$nowcast_big_gram_schmidt_ridge_arima_beginning_of_the_month<- NA

df_forecast_data$nowcast_big_gram_schmidt_sarima_beginning_of_the_month<- NA

df_forecast_data$nowcast_big_elastic_net_beginning_of_the_month<- NA


vars <- result$selected_variables %>%
  janitor::make_clean_names()





###Haciendo el pseudo-out-of-sample
set.seed(123)
start_window <- 30
n <- nrow(df_forecast_data)


tic()
for (t in seq(start_window, n - 1)) {
  
  train_data <- df_forecast_data[1:t, ]
  
  model_big_gram_schmidt <- lm(
    reformulate(c(vars,"dummy_covid1","dummy_covid2"), response = "imae_yoy_log"),
    data = train_data
  )
  
  new_data <- df_forecast_data[t + 1, ]
  

  
  df_forecast_data$nowcast_big_gram_schmidt_beginning_of_the_month[t + 1] <-
    predict(model_big_gram_schmidt, newdata = new_data)
  
  
  x_train <- model.matrix(
    reformulate(c(vars,"dummy_covid1","dummy_covid2"), response = "imae_yoy_log"),
    data = train_data
  )[, -1]
  
  y_train <- train_data$imae_yoy_log
  
  
  cv_ridge <- cv.glmnet(x_train, y_train, alpha = 0)
  
  
  new_data <- df_forecast_data[t + 1, , drop = FALSE]
  

  
  x_new <- model.matrix(
    reformulate(c(vars,"dummy_covid1","dummy_covid2"), response = "imae_yoy_log"),
    data = new_data
  )[, -1]
  
  
  df_forecast_data$nowcast_big_gram_schmidt_shrinkage_beginning_of_the_month[t + 1] <-
    predict(cv_ridge, newx = x_new, s = "lambda.min")
  
  
  cv_ridge <- cv.glmnet(x_train, y_train, alpha = 1)
  
  df_forecast_data$nowcast_big_gram_schmidt_lasso_beginning_of_the_month[t + 1] <-
    predict(cv_ridge, newx = x_new, s = "lambda.min")
  
  
  cv_ridge <- cv.glmnet(x_train, y_train, alpha = 0.5)
  
  df_forecast_data$nowcast_big_gram_schmidt_elastic_net_beginning_of_the_month[t + 1] <-
    predict(cv_ridge, newx = x_new, s = "lambda.min")
  
  cv_ridge <- cv.glmnet(x_train, y_train,alpha=1)
  
  y_hat <- predict(cv_ridge, x_train, s="lambda.min")
  
  res <- y_train - y_hat
  
  fit_arima_res <- Arima(res,order=c(1,0,1),seasonal = list(order=c(0,0,0),period=12))
  
  forecast_arima_res <- forecast(fit_arima_res,h=1)$mean
  
  df_forecast_data$nowcast_big_gram_schmidt_ridge_arima_beginning_of_the_month[t + 1] <- predict(cv_ridge, x_new, s="lambda.min")+forecast_arima_res

  fit_arima_y <- Arima(y_train,order=c(1,0,1),seasonal = list(order=c(1,0,0),period=12))
  
  df_forecast_data$nowcast_big_gram_schmidt_sarima_beginning_of_the_month[t + 1] <- forecast(fit_arima_y,h=1)$mean
  
  train_data_rf  <- train_data[, colSums(is.na(train_data)) == 0]
  
  model_gram_schmidt_random_forest <- randomForest(
    imae_yoy_log ~ . - ano - mes - date
    ,
    data = train_data_rf,
    ntree = 500
  )
  
  df_forecast_data$nowcast_big_random_forest_beginning_of_the_month[t + 1] <-
    predict(model_gram_schmidt_random_forest, newdata = new_data)
  
  train_data_matrix <- train_data_rf%>%select(-c(imae_yoy_log,ano,mes,date))%>%as.matrix()
  
  new_data_matrix  <- new_data[, colSums(is.na(train_data)) == 0]
  
  new_data_matrix <- new_data_matrix%>%select(-c(imae_yoy_log,ano,mes,date))%>%as.matrix()
  
  cv_ridge <- cv.glmnet(train_data_matrix, y_train, alpha = 0.5)
  
  df_forecast_data$nowcast_big_elastic_net_beginning_of_the_month[t + 1] <-
    predict(cv_ridge, newx = new_data_matrix, s = "lambda.min")
  
  
  
  dtrain <- xgb.DMatrix(data = x_train, label = y_train)
  
  
  params <- list(
    objective = "reg:squarederror",
    max_depth = 4,
    eta = 0.1,          # learning rate
    subsample = 0.8,
    colsample_bytree = 0.8
  )
  
  cv <- xgb.cv(
    params = params,
    data = dtrain,
    nrounds = 500,
    nfold = 5,
    early_stopping_rounds = 20,
    verbose = F
  )
  
  xgboost_model <- xgb.train(
    params = params,
    data = dtrain,
    nrounds = cv$best_iteration
  )
  
  x_new <- matrix(x_new, nrow = 1)
  
  df_forecast_data$nowcast_big_gram_schmidt_xgboost_beginning_of_the_month[t + 1] <- predict(xgboost_model, x_new)
  
}
toc()




###Calculando los errores de prediccion y los RMSE
df_forecast_data<-df_forecast_data%>%mutate(
  forecast_error_big_gram_schmidt_beginning_of_the_month=imae_yoy_log-nowcast_big_gram_schmidt_beginning_of_the_month,
  forecast_error_big_gram_schmidt_shrinkage_beginning_of_the_month=imae_yoy_log-nowcast_big_gram_schmidt_shrinkage_beginning_of_the_month,
  forecast_error_big_gram_schmidt_lasso_beginning_of_the_month=imae_yoy_log-nowcast_big_gram_schmidt_lasso_beginning_of_the_month,
  forecast_error_big_gram_schmidt_elastic_net_beginning_of_the_month=imae_yoy_log-nowcast_big_gram_schmidt_elastic_net_beginning_of_the_month,
  forecast_error_big_random_forest_beginning_of_the_month=imae_yoy_log-nowcast_big_random_forest_beginning_of_the_month,
  forecast_error_big_gram_schmidt_xgboost_beginning_of_the_month=imae_yoy_log-nowcast_big_gram_schmidt_xgboost_beginning_of_the_month,
  forecast_error_big_gram_schmidt_ridge_arima_beginning_of_the_month=imae_yoy_log-nowcast_big_gram_schmidt_ridge_arima_beginning_of_the_month,
  forecast_error_big_gram_schmidt_sarima_beginning_of_the_month=imae_yoy_log-nowcast_big_gram_schmidt_sarima_beginning_of_the_month,
  forecast_error_big_elastic_net_beginning_of_the_month=imae_yoy_log-nowcast_big_elastic_net_beginning_of_the_month
)





rmse <- df_forecast_data %>%
  summarise(
    RMSE_big_gram_schmidt_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_shrinkage_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_shrinkage_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_lasso_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_lasso_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_elastic_net_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_elastic_net_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_random_forest_beginning_of_the_month = sqrt(mean(forecast_error_big_random_forest_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_xgboost_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_xgboost_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_ridge_arima_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_ridge_arima_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_sarima_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_sarima_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_elastic_net_beginning_of_the_month = sqrt(mean(forecast_error_big_elastic_net_beginning_of_the_month^2, na.rm = TRUE))
  ) %>%
  unlist()


rmse




rmse_post_covid <- df_forecast_data %>%
  mutate(date = as.Date(as.yearmon(paste(ano, mes), "%Y %m"))) %>%
  dplyr::filter(date>=as.Date("2023-01-01"))%>%
  summarise(
    RMSE_big_gram_schmidt_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_shrinkage_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_shrinkage_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_lasso_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_lasso_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_elastic_net_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_elastic_net_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_random_forest_beginning_of_the_month = sqrt(mean(forecast_error_big_random_forest_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_xgboost_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_xgboost_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_ridge_arima_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_ridge_arima_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_sarima_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_sarima_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_elastic_net_beginning_of_the_month = sqrt(mean(forecast_error_big_elastic_net_beginning_of_the_month^2, na.rm = TRUE))
  ) %>%
  unlist()

rmse_post_covid




rmse_pre_covid <- df_forecast_data %>%
  mutate(date = as.Date(as.yearmon(paste(ano, mes), "%Y %m"))) %>%
  dplyr::filter(date<as.Date("2020-03-01"))%>%
  summarise(
    RMSE_big_gram_schmidt_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_shrinkage_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_shrinkage_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_lasso_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_lasso_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_elastic_net_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_elastic_net_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_random_forest_beginning_of_the_month = sqrt(mean(forecast_error_big_random_forest_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_xgboost_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_xgboost_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_ridge_arima_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_ridge_arima_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_gram_schmidt_sarima_beginning_of_the_month = sqrt(mean(forecast_error_big_gram_schmidt_sarima_beginning_of_the_month^2, na.rm = TRUE)),
    RMSE_big_elastic_net_beginning_of_the_month = sqrt(mean(forecast_error_big_elastic_net_beginning_of_the_month^2, na.rm = TRUE))
  ) %>%
  unlist()

rmse_pre_covid




plot_ly(df_forecast_data%>%
          dplyr::filter(date >= as.Date("2022-03-01") ), x = ~date) %>%
  add_lines(y = ~imae_yoy_log, name = "IMAE") %>%
  add_lines(y = ~nowcast_big_gram_schmidt_shrinkage_beginning_of_the_month, name = "Predicción")


df_plot <- df_forecast_data%>%
  dplyr::filter(date>=as.Date('2023-01-01'))


result <- plot_regression_efficiency(
  df_plot,
  nowcast_big_gram_schmidt_shrinkage_beginning_of_the_month,
  imae_yoy_log
)

result



result <- plot_regression_efficiency(
  df_plot,
  nowcast_big_gram_schmidt_xgboost_beginning_of_the_month,
  imae_yoy_log
)

result
