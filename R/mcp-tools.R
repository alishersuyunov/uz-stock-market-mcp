root_dir <- Sys.getenv("UZ_STOCK_MCP_ROOT", unset = "")
if (!nzchar(root_dir)) {
  stop(
    "UZ_STOCK_MCP_ROOT is not set. Start the server via run-mcp.R or set the environment variable before sourcing R/mcp-tools.R.",
    call. = FALSE
  )
}

# Enum constant vectors (sector_values, security_type_values, etc.) and all
# wrapper functions are defined in wrappers.R and available here after source().
source(file.path(root_dir, "R", "wrappers.R"), local = TRUE, chdir = FALSE)

read_only_annotations <- function(title) {
  ellmer::tool_annotations(
    title            = title,
    read_only_hint   = TRUE,
    open_world_hint  = TRUE,
    idempotent_hint  = TRUE,
    destructive_hint = FALSE
  )
}

tool_definitions <- list(
  registered_securities = ellmer::tool(
    registered_securities,
    name        = "registered_securities",
    description = "Fetch the full list of registered securities from the Central Securities Depository of Uzbekistan.",
    annotations = read_only_annotations("Registered Securities")
  ),
  securities = ellmer::tool(
    securities,
    name        = "securities",
    description = "Fetch the list of securities currently listed on the Republican Stock Exchange Toshkent.",
    annotations = read_only_annotations("Exchange Securities")
  ),
  ticker_history = ellmer::tool(
    ticker_history,
    name        = "ticker_history",
    description = "Fetch historical stock price data for one or more Uzbek securities by security code or ticker symbol.",
    arguments   = list(
      symbols = ellmer::type_array(
        items       = ellmer::type_string("One security code or ticker symbol."),
        description = "One or more security codes or ticker symbols.",
        required    = TRUE
      ),
      from = ellmer::type_string(
        "Start date in YYYY-MM-DD format.",
        required = FALSE
      ),
      to = ellmer::type_string(
        "End date in YYYY-MM-DD format. Omit to default to today.",
        required = FALSE
      )
    ),
    annotations = read_only_annotations("Ticker History")
  ),
  market_index = ellmer::tool(
    market_index,
    name        = "market_index",
    description = "Fetch Uzbekistan Composite Index data for a market sector and date range.",
    arguments   = list(
      sector = ellmer::type_enum(
        values      = sector_values,
        description = "Market sector to retrieve.",
        required    = FALSE
      ),
      from = ellmer::type_string(
        "Start date in YYYY-MM-DD format.",
        required = FALSE
      ),
      to = ellmer::type_string(
        "End date in YYYY-MM-DD format. Omit to default to today.",
        required = FALSE
      )
    ),
    annotations = read_only_annotations("Market Index")
  ),
  current_bids_asks = ellmer::tool(
    current_bids_asks,
    name        = "current_bids_asks",
    description = "Fetch the current bids and asks from the Republican Stock Exchange Toshkent, optionally filtered by security code and market type.",
    arguments   = list(
      security_code = ellmer::type_string(
        "Optional security code filter. Omit for all securities in the selected market type.",
        required = FALSE
      ),
      security_type = ellmer::type_enum(
        values      = security_type_values,
        description = "Security market type filter.",
        required    = FALSE
      )
    ),
    annotations = read_only_annotations("Current Bids and Asks")
  ),
  ipo_calendar = ellmer::tool(
    ipo_calendar,
    name        = "ipo_calendar",
    description = "Fetch the public offering calendar from the Uzbek exchange, optionally filtered by a search key.",
    arguments   = list(
      search_key = ellmer::type_string(
        "Optional search key to filter offering results.",
        required = FALSE
      ),
      plus_n_years = ellmer::type_integer(
        "How many years ahead to include when building the schedule date filter.",
        required = FALSE
      )
    ),
    annotations = read_only_annotations("IPO Calendar")
  ),
  fx_rates = ellmer::tool(
    fx_rates,
    name        = "fx_rates",
    description = "Fetch foreign exchange rate history from the Republican Currency Exchange of Uzbekistan.",
    arguments   = list(
      currency = ellmer::type_enum(
        values      = fx_currency_values,
        description = "Currency code to retrieve.",
        required    = FALSE
      ),
      from = ellmer::type_string(
        "Start date in YYYY-MM-DD format.",
        required = FALSE
      ),
      to = ellmer::type_string(
        "End date in YYYY-MM-DD format. Omit to default to today.",
        required = FALSE
      )
    ),
    annotations = read_only_annotations("FX Rates")
  ),
  all_issuers = ellmer::tool(
    all_issuers,
    name        = "all_issuers",
    description = "Fetch the full list of issuer records from the Central Securities Depository of Uzbekistan.",
    annotations = read_only_annotations("All Issuers")
  ),
  dividends = ellmer::tool(
    dividends,
    name        = "dividends",
    description = "Fetch the dividend calendar for Uzbek securities, optionally filtered by stock type.",
    arguments   = list(
      stock_type = ellmer::type_enum(
        values      = dividend_type_values,
        description = "Dividend stock type filter.",
        required    = FALSE
      )
    ),
    annotations = read_only_annotations("Dividends")
  )
)

tool_definitions
