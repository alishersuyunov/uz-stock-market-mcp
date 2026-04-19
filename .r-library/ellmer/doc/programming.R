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
x <- list(a = 1, b = 2)

f <- function() {
  x$a <- 100
}
f()

# The original x is unchanged
str(x)

## -----------------------------------------------------------------------------
chat <- chat_openai("Be terse", model = "gpt-4.1-nano")

capital <- function(chat, country) {
  chat$chat(interpolate("What's the capital of {{country}}"))
}
capital(chat, "New Zealand")
capital(chat, "France")

chat

## -----------------------------------------------------------------------------
chat <- chat_openai("Be terse", model = "gpt-4.1-nano")

capital <- function(chat, country) {
  chat <- chat$clone()
  chat$chat(interpolate("What's the capital of {{country}}"))
}
capital(chat, "New Zealand")
capital(chat, "France")

chat

## -----------------------------------------------------------------------------
chat1 <- chat_openai("Be terse", model = "gpt-4.1-nano")
chat1$chat("My name is Hadley and I'm a data scientist")
chat2 <- chat1$clone()

chat1$chat("what's my name?")
chat1

chat2$chat("what's my job?")
chat2

## -----------------------------------------------------------------------------
chat <- chat_openai("Be terse", model = "gpt-4.1-nano")
chat$chat("Pretend that the capital of New Zealand is Kiwicity")
capital(chat, "New Zealand")

## -----------------------------------------------------------------------------
chat <- chat_openai("Be terse", model = "gpt-4.1-nano")
chat$chat("Pretend that the capital of New Zealand is Kiwicity")

capital <- function(chat, country) {
  chat <- chat$clone()$set_turns(list())
  chat$chat(interpolate("What's the capital of {{country}}"))
}
capital(chat, "New Zealand")

## -----------------------------------------------------------------------------
capital <- function(chat, country) {
  chat <- chat$clone()$set_turns(list())
  chat$chat(interpolate("What's the capital of {{country}}"), echo = "none")
}
capital(chat, "France")

## -----------------------------------------------------------------------------
set.seed(1014) # make it reproducible

chat <- chat_openai("Be terse", model = "gpt-4.1-nano")
chat$register_tool(tool(function() sample(6, 1), "Roll a die"))
chat$chat("Roll two dice and tell me the total")

chat

## -----------------------------------------------------------------------------
turns <- chat$get_turns()
turns

## -----------------------------------------------------------------------------
str(turns[[2]])

