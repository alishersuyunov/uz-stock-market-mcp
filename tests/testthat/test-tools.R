testthat::test_that("tool definitions load with the expected names", {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    testthat::skip("ellmer is not installed")
  }

  tools <- load_mcp_tools()
  expected_names <- c(
    "registered_securities",
    "securities",
    "ticker_history",
    "market_index",
    "current_bids_asks",
    "ipo_calendar",
    "fx_rates",
    "all_issuers",
    "dividends"
  )

  testthat::expect_equal(names(tools), expected_names)
  testthat::expect_length(tools, length(expected_names))
  testthat::expect_true(all(vapply(
    tools,
    function(tool) any(grepl("ToolDef", class(tool), fixed = TRUE)),
    logical(1)
  )))
})
