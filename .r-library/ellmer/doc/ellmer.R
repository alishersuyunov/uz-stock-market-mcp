## -----------------------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = ellmer:::eval_vignette()
)
vcr::setup_knitr()

## ----setup--------------------------------------------------------------------
library(ellmer)

## -----------------------------------------------------------------------------
chat <- chat_openai(model = "gpt-4.1")
. <- chat$chat("Who created R?", echo = FALSE)
chat

token_usage()

