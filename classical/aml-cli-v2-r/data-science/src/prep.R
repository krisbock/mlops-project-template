library(optparse)
library(carrier)

# Loading azureml_utils.R. This is needed to use AML as MLflow backend tracking store.
source('azureml_utils.R')

# Setting MLflow related env vars
# https://www.mlflow.org/docs/latest/R-api.html#details
#Sys.setenv(MLFLOW_BIN=system("which mlflow", intern=TRUE))
#Sys.setenv(MLFLOW_PYTHON_BIN=system("which python", intern=TRUE))
Sys.setenv(MLFLOW_BIN="/home/krbock/miniconda3/envs/r-mlflow-1.27.0/bin/mlflow")
Sys.setenv(MLFLOW_PYTHON_BIN="/home/krbock/miniconda3/envs/r-mlflow-1.27.0/bin/python")

options <- list(
  make_option(c("-r", "--raw_folder"), default="../../data"),
  make_option(c("-p", "--prepared_folder"), default="../../processed")
)

opt_parser <- OptionParser(option_list = options)
opt <- parse_args(opt_parser)

paste(opt$raw_data)

accidents <- readRDS(file.path(opt$raw_data, "accidents.Rd"))
summary(accidents)

# Split the data into training and test sets. (0.75, 0.25) split.
sampled <- sample(1:nrow(accidents), 0.75 * nrow(accidents))
train <- accidents[sampled, ]
test <- accidents[-sampled, ]

mlflow_log_metric("train size", dim(train)[1])
mlflow_log_metric("test size", dim(test)[1])

if (!dir.exists(opt$prepared_data)) dir.create(opt$prepared_data, recursive = TRUE)

write.csv(train, file.path(opt$prepared_data, "train.csv"))
write.csv(test, file.path(opt$prepared_data, "test.csv"))
