library(kernlab)
library(caret)

# Caret's predict method only allows type to be "prob" or "raw.
# We will dig out the ksvm fit object from Caret's fit object and
# call its predict method directly.
my_predict <- function(fit, newdata, type="response") {
  newdata <- predict(fit$preProcess, newdata)  # Preprocess the data the same way Caret does
  newdata <- newdata %>% select(-any_of(c("sex", "Hb", "Hb_deferral"))) 
  res <- predict(fit$finalModel, newdata=newdata, type=type) # Call underlying object's predict method
  return(res)
}

# Test it on a working male svm fit
base <- "~/FRCBS/Hb_predictor_container/results/jarkko-2022-01-18-bl-rf-svm/tmp"
fit_filename <- paste(base, "svm-fit-male.rds", sep = "/")
validate_filename <- paste(base, "svm-validate-male.rds", sep = "/")
train_filename <- paste(base, "svm-train-male.rds", sep="/")
fit <- readRDS(fit_filename)
validate <- readRDS(validate_filename)
train <- readRDS(train_filename)

# Get the roc creation function
source("~/FRCBS/Hb_predictor_container/src/validate_stan_fit.R", chdir = TRUE)

df <- tibble(original_label = validate$Hb_deferral == "Deferred",
             decision = my_predict(fit, validate, "decision")[,1])
# Check whether the Platt scaling worked or not 
res = tryCatch(error=function(e) NULL, my_predict(fit, validate, "probabilities")[,"Deferred"])
if (!is.null(res)) df$prob <- res

# These should look the same
roc1 <- create_roc_new(df$original_label, df$decision)
if (!is.null(res)) {
  roc2 <- create_roc_new(df$original_label, df$prob)
} else{
  roc2 <- NULL
}