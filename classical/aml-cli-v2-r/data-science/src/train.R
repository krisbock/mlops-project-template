library(optparse)
library(carrier)

# Loading azureml_utils.R. This is needed to use AML as MLflow backend tracking store.
source('azureml_utils.R')

# Setting MLflow related env vars
# https://www.mlflow.org/docs/latest/R-api.html#details
Sys.setenv(MLFLOW_BIN=system("which mlflow", intern=TRUE))
Sys.setenv(MLFLOW_PYTHON_BIN=system("which python", intern=TRUE))
#Sys.setenv(MLFLOW_BIN="/home/krbock/miniconda3/envs/r-mlflow-1.27.0/bin/mlflow")
#Sys.setenv(MLFLOW_PYTHON_BIN="/home/krbock/miniconda3/envs/r-mlflow-1.27.0/bin/python")

options <- list(
  make_option(c("-p", "--prepared_folder"), default="../../processed")
)

opt_parser <- OptionParser(option_list = options)
opt <- parse_args(opt_parser)

paste(opt$prepared_folder)

train <- read.csv(file.path(opt$prepared_folder, "train.csv"))
test <- read.csv(file.path(opt$prepared_folder, "test.csv"))

# The predicted column is "quality" which is a scalar from [3, 9]
train_x <- as.matrix(train[, !(names(train) == "dead")])
test_x <- as.matrix(test[, !(names(train) == "dead")])
train_y <- train[, "dead"]
test_y <- test[, "dead"]

alpha <- mlflow_param("alpha", 0.5, "numeric")
lambda <- mlflow_param("lambda", 0.5, "numeric")

with(mlflow_start_run(), {
    model <- glmnet(train_x, train_y, alpha = alpha, lambda = lambda, family= "gaussian", standardize = FALSE)
    predictor <- crate(~ glmnet::predict.glmnet(!!model, as.matrix(.x)), !!model)
    predicted <- predictor(test_x)

    rmse <- sqrt(mean((predicted - test_y) ^ 2))
    mae <- mean(abs(predicted - test_y))
    r2 <- as.numeric(cor(predicted, test_y) ^ 2)

    message("Elasticnet model (alpha=", alpha, ", lambda=", lambda, "):")
    message("  RMSE: ", rmse)
    message("  MAE: ", mae)
    message("  R2: ", r2)

    mlflow_log_param("alpha", alpha)
    mlflow_log_param("lambda", lambda)
    mlflow_log_metric("rmse", rmse)
    mlflow_log_metric("r2", r2)
    mlflow_log_metric("mae", mae)

    mlflow_log_model(predictor, "model")
})
