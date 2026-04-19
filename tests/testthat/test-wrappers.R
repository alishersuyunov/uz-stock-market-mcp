testthat::test_that("registered securities wrapper returns an MCP envelope", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }

  result <- registered_securities()

  testthat::expect_equal(result$source_function, "RegisteredSecurities")
  testthat::expect_true(is.numeric(result$row_count))
  testthat::expect_true(is.list(result$columns))
  testthat::expect_true(is.list(result$records))
})

testthat::test_that("securities wrapper exposes the expected column names", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }

  result <- securities()
  column_names <- vapply(result$columns, `[[`, character(1), "name")

  testthat::expect_equal(column_names, c("Type", "SecurityCode", "Ticker", "Issuer"))
})

testthat::test_that("ticker history supports multiple symbols", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }

  result <- ticker_history(
    symbols = c("KVTS", "UZTL"),
    from = "2024-01-01",
    to = "2024-02-01"
  )

  symbols <- unique(vapply(result$records, function(record) record$symbol, character(1)))

  testthat::expect_true(result$row_count > 0)
  testthat::expect_equal(sort(symbols), sort(c("UZ7025770007", "UZ7047110000")))
})

testthat::test_that("date validation errors remain concise", {
  testthat::expect_error(
    market_index(
      sector = "finance",
      from = "2020-01-01",
      to = "30.06.2020"
    ),
    "getMarketIndex failed:"
  )

  testthat::expect_error(
    fx_rates(
      currency = "USD",
      from = "2020-01-01",
      to = "30-06-2020"
    ),
    "get_FX failed:"
  )
})

testthat::test_that("current bids and dividends return tabular envelopes", {
  if (!requireNamespace("opendatauzb", quietly = TRUE)) {
    testthat::skip("opendatauzb is not installed")
  }

  bids <- current_bids_asks()
  dividend_calendar <- dividends()

  testthat::expect_equal(bids$source_function, "currentBidsAsks")
  testthat::expect_true(is.list(bids$records))
  testthat::expect_equal(dividend_calendar$source_function, "getDividends")
  testthat::expect_true(is.list(dividend_calendar$records))
})
