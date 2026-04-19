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
chat <- chat_openai()
chat$chat_structured(
  "My name is Susan and I'm 13 years old",
  type = type_object(
    name = type_string(),
    age = type_number()
  )
)

## -----------------------------------------------------------------------------
chat <- chat_openai()
chat$chat_structured(
  content_image_url("https://www.r-project.org/Rlogo.png"),
  type = type_object(
    primary_shape = type_string(),
    primary_colour = type_string()
  )
)

## -----------------------------------------------------------------------------
prompts <- list(
  "I go by Alex. 42 years on this planet and counting.",
  "Pleased to meet you! I'm Jamal, age 27.",
  "They call me Li Wei. Nineteen years young.",
  "Fatima here. Just celebrated my 35th birthday last week.",
  "The name's Robert - 51 years old and proud of it.",
  "Kwame here - just hit the big 5-0 this year."
)
type_person <- type_object(
  name = type_string(),
  age = type_number()
)
chat <- chat_openai()
parallel_chat_structured(chat, prompts, type = type_person)

## -----------------------------------------------------------------------------
type_logical_vector <- type_array(type_boolean())
type_integer_vector <- type_array(type_integer())
type_double_vector <- type_array(type_number())
type_character_vector <- type_array(type_string())

## -----------------------------------------------------------------------------
list_of_integers <- type_array(type_integer_vector)

## -----------------------------------------------------------------------------
type_person2 <- type_object(
name = type_string(),
age = type_integer(),
hobbies = type_array(type_string())
)

## -----------------------------------------------------------------------------
type_person3 <- type_object(
  "A person",
  name = type_string("Name"),
  age = type_integer("Age, in years."),
  hobbies = type_array(
    type_string(),
    "List of hobbies. Should be exclusive and brief.",
  )
)

## -----------------------------------------------------------------------------
no_match <- list(
  "I like apples",
  "What time is it?",
  "This cheese is 3 years old",
  "My name is Hadley."
)
parallel_chat_structured(chat, no_match, type = type_person)

## -----------------------------------------------------------------------------
type_person <- type_object(
  name = type_string(required = FALSE),
  age = type_number(required = FALSE)
)
parallel_chat_structured(chat, no_match, type = type_person)

## -----------------------------------------------------------------------------
prompt <- r"(
* John Smith. Age: 30. Height: 180 cm. Weight: 80 kg.
* Jane Doe. Age: 25. Height: 5'5". Weight: 110 lb.
* Jose Rodriguez. Age: 40. Height: 190 cm. Weight: 90 kg.
* June Lee | Age: 35 | Height 175 cm | Weight: 70 kg
)"

## -----------------------------------------------------------------------------
type_people <- type_object(
  name = type_array(type_string()),
  age = type_array(type_integer()),
  height = type_array(type_number("in m")),
  weight = type_array(type_number("in kg"))
)

chat <- chat_openai()
chat$chat_structured(prompt, type = type_people)

## -----------------------------------------------------------------------------
type_people <- type_array(
  type_object(
    name = type_string(),
    age = type_integer(),
    height = type_number("in m"),
    weight = type_number("in kg")
  )
)

chat <- chat_openai()
chat$chat_structured(prompt, type = type_people)

## -----------------------------------------------------------------------------
text <- readLines(system.file(
  "examples/third-party-testing.txt",
  package = "ellmer"
))
# url <- "https://www.anthropic.com/news/third-party-testing"
# html <- rvest::read_html(url)
# text <- rvest::html_text2(rvest::html_element(html, "article"))

type_summary <- type_object(
  "Summary of the article.",
  author = type_string("Name of the article author"),
  topics = type_array(
    type_string(),
    'Array of topics, e.g. ["tech", "politics"]. Should be as specific as possible, and can overlap.'
  ),
  summary = type_string("Summary of the article. One or two paragraphs max"),
  coherence = type_integer(
    "Coherence of the article's key points, 0-100 (inclusive)"
  ),
  persuasion = type_number("Article's persuasion score, 0.0-1.0 (inclusive)")
)

chat <- chat_openai()
data <- chat$chat_structured(text, type = type_summary)
cat(data$summary)

str(data)

## -----------------------------------------------------------------------------
text <- "
  John works at Google in New York. He met with Sarah, the CEO of
  Acme Inc., last week in San Francisco.
"

type_named_entity <- type_object(
  name = type_string("The extracted entity name."),
  type = type_enum(c("person", "location", "organization"), "The entity type"),
  context = type_string("The context in which the entity appears in the text.")
)
type_named_entities <- type_array(type_named_entity)

chat <- chat_openai()
chat$chat_structured(text, type = type_named_entities)

## -----------------------------------------------------------------------------
text <- "
  The product was okay, but the customer service was terrible. I probably
  won't buy from them again.
"

type_sentiment <- type_object(
  "Extract the sentiment scores of a given text. Sentiment scores should sum to 1.",
  positive_score = type_number(
    "Positive sentiment score, ranging from 0.0 to 1.0."
  ),
  negative_score = type_number(
    "Negative sentiment score, ranging from 0.0 to 1.0."
  ),
  neutral_score = type_number(
    "Neutral sentiment score, ranging from 0.0 to 1.0."
  )
)

chat <- chat_openai()
str(chat$chat_structured(text, type = type_sentiment))

## -----------------------------------------------------------------------------
text <- "The new quantum computing breakthrough could revolutionize the tech industry."

type_score <- type_object(
  name = type_enum(
    c(
      "Politics",
      "Sports",
      "Technology",
      "Entertainment",
      "Business",
      "Other"
    ),
    "The category name",
  ),
  score = type_number(
    "The classification score for the category, ranging from 0.0 to 1.0."
  )
)
type_classification <- type_array(
  type_score,
  description = "Array of classification results. The scores should sum to 1."
)

chat <- chat_openai()
data <- chat$chat_structured(text, type = type_classification)
data

## -----------------------------------------------------------------------------
type_characteristics <- type_object(
  "All characteristics",
  .additional_properties = TRUE
)

text <- "
  The man is tall, with a beard and a scar on his left cheek. He has a deep voice and wears a black leather jacket.
"

chat <- chat_anthropic("Extract all characteristics of supplied character")
str(chat$chat_structured(text, type = type_characteristics))

## -----------------------------------------------------------------------------
type_asset <- type_object(
  assert_name = type_string(),
  owner = type_string(),
  location = type_string(),
  asset_value_low = type_integer(),
  asset_value_high = type_integer(),
  income_type = type_string(),
  income_low = type_integer(),
  income_high = type_integer(),
  tx_gt_1000 = type_boolean()
)
type_assets <- type_array(type_asset)

chat <- chat_openai()
image <- content_image_file("congressional-assets.png")
data <- chat$chat_structured(image, type = type_assets)
data

## -----------------------------------------------------------------------------
knitr::kable(token_usage())

