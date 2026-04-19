## -----------------------------------------------------------------------------
s = "hey ho, let's go!"
gsub("hey", "ho", s)

## -----------------------------------------------------------------------------
s = "hey ho, let's go!"
gsub("hey|ho", "yo", s)

## -----------------------------------------------------------------------------
s = "hey ho, let's go!"
s_new = gsub("hey", "get", s)
s_new = gsub("ho", "ready", s_new)
s_new

## -----------------------------------------------------------------------------
s = "hey ho, let's go!"
s_new = gsub("hey", "ho", s)
s_new = gsub("ho", "hey", s_new)
s_new

## -----------------------------------------------------------------------------
library(mgsub)
s = "hey ho, let's go!"
mgsub::mgsub(string = s, pattern = c("hey", "ho"), replacement = c("ho", "hey"))

## -----------------------------------------------------------------------------
s = "Dopazamine is not the same as dopachloride or dopastriamine, yet is still fake."
pattern = c("[Dd]opa([^ ]*?mine)", "fake")
replacement = c("Meta\\1", "real")
mgsub::mgsub(s, pattern, replacement)

## -----------------------------------------------------------------------------
s = "All my life I chased $money$ and .power. - not love!"
pattern = c("$money$", ".power.", "love")
replacement = c("balloons", "dolphins", "success")
mgsub::mgsub(s, pattern, replacement, fixed = TRUE)

