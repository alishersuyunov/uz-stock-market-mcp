# ---------------------------------------------------------------------------
# Validation and transformation tests — no opendatauzb required
# ---------------------------------------------------------------------------

testthat::test_that("validate_iso_date rejects non-YYYY-MM-DD patterns", {
  testthat::expect_error(validate_iso_date("01.01.2020", "from"), "YYYY-MM-DD")
  testthat::expect_error(validate_iso_date("01-01-2020", "from"), "YYYY-MM-DD")
  testthat::expect_error(validate_iso_date("2020/01/01", "from"), "YYYY-MM-DD")
  testthat::expect_error(validate_iso_date("20200101",   "from"), "YYYY-MM-DD")
})

testthat::test_that("validate_iso_date rejects structurally valid but impossible dates", {
  testthat::expect_error(validate_iso_date("2020-13-01", "from"), "valid calendar date")
  testthat::expect_error(validate_iso_date("2020-01-32", "from"), "valid calendar date")
})

testthat::test_that("validate_iso_date accepts valid YYYY-MM-DD dates", {
  testthat::expect_equal(validate_iso_date("2020-01-01", "from"), "2020-01-01")
  testthat::expect_equal(validate_iso_date("2024-12-31", "to"),   "2024-12-31")
})

testthat::test_that("iso_to_dmy_dot converts YYYY-MM-DD to DD.MM.YYYY", {
  testthat::expect_equal(iso_to_dmy_dot("2020-01-01"), "01.01.2020")
  testthat::expect_equal(iso_to_dmy_dot("2024-06-30"), "30.06.2024")
})

testthat::test_that("iso_to_dmy_dash converts YYYY-MM-DD to DD-MM-YYYY", {
  testthat::expect_equal(iso_to_dmy_dash("2022-01-01"), "01-01-2022")
  testthat::expect_equal(iso_to_dmy_dash("2024-06-30"), "30-06-2024")
})

testthat::test_that("validate_date_range rejects from > to", {
  testthat::expect_error(
    validate_date_range("2024-06-30", "2024-01-01"),
    "must not be after"
  )
})

testthat::test_that("validate_date_range accepts from == to", {
  testthat::expect_invisible(validate_date_range("2024-01-01", "2024-01-01"))
})

testthat::test_that("validate_enum rejects values outside the allowed set", {
  testthat::expect_error(
    validate_enum("unknown", c("all", "finance"), "sector"),
    "must be one of"
  )
  testthat::expect_error(
    validate_enum("GBP", c("USD", "EUR"), "currency"),
    "must be one of"
  )
})

testthat::test_that("serialize_table handles an empty data.frame without error", {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    testthat::skip("jsonlite not installed")
  }
  result <- serialize_table(data.frame(), "TestFn")
  testthat::expect_equal(result$source_function, "TestFn")
  testthat::expect_equal(result$row_count, 0L)
  testthat::expect_equal(result$columns, list())
  testthat::expect_equal(result$records, list())
})

# --- market_index date input validation (no network call) -------------------

testthat::test_that("market_index rejects non-ISO from date", {
  testthat::expect_error(
    market_index(from = "01.01.2020"),
    "`from` must be in YYYY-MM-DD format"
  )
})

testthat::test_that("market_index rejects non-ISO to date", {
  testthat::expect_error(
    market_index(to = "30.06.2024"),
    "`to` must be in YYYY-MM-DD format"
  )
})

testthat::test_that("market_index rejects invalid sector", {
  testthat::expect_error(
    market_index(sector = "xyz"),
    "must be one of"
  )
})

# --- fx_rates date input validation (no network call) -----------------------

testthat::test_that("fx_rates rejects non-ISO from date", {
  testthat::expect_error(
    fx_rates(from = "01-01-2022"),
    "`from` must be in YYYY-MM-DD format"
  )
})

testthat::test_that("fx_rates rejects non-ISO to date", {
  testthat::expect_error(
    fx_rates(to = "30-06-2024"),
    "`to` must be in YYYY-MM-DD format"
  )
})

testthat::test_that("fx_rates rejects unsupported currency", {
  testthat::expect_error(
    fx_rates(currency = "GBP"),
    "must be one of"
  )
})

# --- ticker_history input validation (no network call) ----------------------

testthat::test_that("ticker_history rejects non-ISO from date", {
  testthat::expect_error(
    ticker_history(symbols = "KVTS", from = "01.01.2020"),
    "`from` must be in YYYY-MM-DD format"
  )
})

testthat::test_that("ticker_history rejects from > to", {
  testthat::expect_error(
    ticker_history(symbols = "KVTS", from = "2024-06-30", to = "2024-01-01"),
    "must not be after"
  )
})

testthat::test_that("ticker_history rejects empty symbols array", {
  testthat::expect_error(
    ticker_history(symbols = character(0)),
    "at least one symbol"
  )
})

# --- Other enum validation (no network call) --------------------------------

testthat::test_that("current_bids_asks rejects invalid security_type", {
  testthat::expect_error(
    current_bids_asks(security_type = "XYZ"),
    "must be one of"
  )
})

testthat::test_that("dividends rejects invalid stock_type", {
  testthat::expect_error(
    dividends(stock_type = "xyz"),
    "must be one of"
  )
})

testthat::test_that("market_index rejects impossible date range", {
  testthat::expect_error(
    market_index(from = "2024-06-30", to = "2024-01-01"),
    "must not be after"
  )
})

# ---------------------------------------------------------------------------
# Contract and integration tests — require opendatauzb
# ---------------------------------------------------------------------------

testthat::test_that("registered_securities returns an MCP envelope", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }
  result <- registered_securities()
  testthat::expect_equal(result$source_function, "RegisteredSecurities")
  testthat::expect_true(is.numeric(result$row_count))
  testthat::expect_true(is.list(result$columns))
  testthat::expect_true(is.list(result$records))
})

testthat::test_that("securities exposes the expected column names", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }
  result <- securities()
  column_names <- vapply(result$columns, `[[`, character(1), "name")
  testthat::expect_equal(column_names, c("Type", "SecurityCode", "Ticker", "Issuer"))
})

testthat::test_that("ticker_history supports multiple symbols", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }
  result <- ticker_history(
    symbols = c("KVTS", "UZTL"),
    from    = "2024-01-01",
    to      = "2024-02-01"
  )
  symbols <- unique(vapply(result$records, function(r) r$symbol, character(1)))
  testthat::expect_true(result$row_count > 0)
  testthat::expect_equal(sort(symbols), sort(c("UZ7025770007", "UZ7047110000")))
})

testthat::test_that("market_index accepts ISO dates and calls upstream successfully", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }
  result <- market_index(sector = "finance", from = "2024-01-01", to = "2024-06-30")
  testthat::expect_equal(result$source_function, "getMarketIndex")
  testthat::expect_true(is.list(result$records))
})

testthat::test_that("fx_rates accepts ISO dates and calls upstream successfully", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }
  result <- fx_rates(currency = "USD", from = "2024-01-01", to = "2024-06-30")
  testthat::expect_equal(result$source_function, "get_FX")
  testthat::expect_true(is.list(result$records))
})

testthat::test_that("current_bids_asks returns a tabular envelope", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }
  result <- current_bids_asks()
  testthat::expect_equal(result$source_function, "currentBidsAsks")
  testthat::expect_true(is.list(result$records))
})

testthat::test_that("dividends returns a tabular envelope", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }
  result <- dividends()
  testthat::expect_equal(result$source_function, "getDividends")
  testthat::expect_true(is.list(result$records))
})

testthat::test_that("all_issuers returns an MCP envelope", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }
  result <- all_issuers()
  testthat::expect_equal(result$source_function, "getAllIssuers")
  testthat::expect_true(is.numeric(result$row_count))
  testthat::expect_true(is.list(result$records))
})

testthat::test_that("ipo_calendar returns an MCP envelope", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }
  result <- ipo_calendar()
  testthat::expect_equal(result$source_function, "ipo")
  testthat::expect_true(is.list(result$records))
})
