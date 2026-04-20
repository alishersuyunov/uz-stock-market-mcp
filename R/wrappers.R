# Allowed enum values — shared by wrapper validation and MCP tool definitions.
sector_values        <- c("all", "finance", "industry", "agriculture",
                          "construction", "social", "transport", "trade", "other")
security_type_values <- c("STK", "BND", "RPO", "FCT")
dividend_type_values <- c("all", "privileged", "simple", "bond")
fx_currency_values   <- c("USD", "EUR")

# ---------------------------------------------------------------------------
# Package guard
# ---------------------------------------------------------------------------

ensure_namespace <- function(package_name) {
  if (!requireNamespace(package_name, quietly = TRUE)) {
    stop(
      sprintf(
        "Missing required package '%s'. Run scripts/bootstrap.R first.",
        package_name
      ),
      call. = FALSE
    )
  }
}

# ---------------------------------------------------------------------------
# String normalizers
# ---------------------------------------------------------------------------

normalize_scalar_string <- function(
  value,
  argument_name,
  default = NULL,
  allow_empty = FALSE,
  transform = identity
) {
  if (is.null(value)) {
    if (!is.null(default)) {
      value <- default
    } else {
      stop(sprintf("`%s` must not be NULL.", argument_name), call. = FALSE)
    }
  }

  if (length(value) != 1) {
    stop(sprintf("`%s` must be a single string.", argument_name), call. = FALSE)
  }

  value <- as.character(value)
  value <- trimws(value)
  value <- transform(value)

  if (!allow_empty && !nzchar(value)) {
    stop(sprintf("`%s` must not be empty.", argument_name), call. = FALSE)
  }

  value
}

normalize_string_array <- function(value, argument_name) {
  if (is.null(value)) {
    stop(sprintf("`%s` must not be NULL.", argument_name), call. = FALSE)
  }

  if (is.list(value)) {
    value <- unlist(value, use.names = FALSE)
  }

  value <- as.character(value)
  value <- trimws(value)
  value <- value[nzchar(value)]

  if (length(value) == 0) {
    stop(sprintf("`%s` must contain at least one symbol.", argument_name), call. = FALSE)
  }

  unname(value)
}

# ---------------------------------------------------------------------------
# Date helpers
#
# All MCP-facing date parameters use YYYY-MM-DD. Tools whose upstream
# functions expect a different format convert internally using the helpers
# below. Users should never need to know about DD.MM.YYYY or DD-MM-YYYY.
# ---------------------------------------------------------------------------

validate_iso_date <- function(value, argument_name) {
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", value)) {
    stop(
      sprintf(
        "`%s` must be in YYYY-MM-DD format (got '%s').",
        argument_name, value
      ),
      call. = FALSE
    )
  }
  parsed <- suppressWarnings(as.Date(value, format = "%Y-%m-%d"))
  if (is.na(parsed)) {
    stop(
      sprintf(
        "`%s` is not a valid calendar date: '%s'.",
        argument_name, value
      ),
      call. = FALSE
    )
  }
  value
}

# Returns today as YYYY-MM-DD when value is NULL; otherwise validates ISO format.
resolve_iso_date <- function(value, argument_name) {
  if (is.null(value)) {
    return(format(Sys.Date(), "%Y-%m-%d"))
  }
  value <- normalize_scalar_string(value, argument_name)
  validate_iso_date(value, argument_name)
  value
}

validate_date_range <- function(from_iso, to_iso,
                                from_name = "from", to_name = "to") {
  if (as.Date(from_iso) > as.Date(to_iso)) {
    stop(
      sprintf(
        "`%s` (%s) must not be after `%s` (%s).",
        from_name, from_iso, to_name, to_iso
      ),
      call. = FALSE
    )
  }
  invisible(NULL)
}

# ISO YYYY-MM-DD → DD.MM.YYYY (required by getMarketIndex upstream)
iso_to_dmy_dot  <- function(iso_date) format(as.Date(iso_date), "%d.%m.%Y")

# ISO YYYY-MM-DD → DD-MM-YYYY (required by get_FX upstream)
iso_to_dmy_dash <- function(iso_date) format(as.Date(iso_date), "%d-%m-%Y")

# ---------------------------------------------------------------------------
# Enum helper
# ---------------------------------------------------------------------------

validate_enum <- function(value, allowed, argument_name) {
  if (!value %in% allowed) {
    stop(
      sprintf(
        "`%s` must be one of %s (got '%s').",
        argument_name,
        paste(sprintf("'%s'", allowed), collapse = ", "),
        value
      ),
      call. = FALSE
    )
  }
  invisible(value)
}

# ---------------------------------------------------------------------------
# Serialization helpers
# ---------------------------------------------------------------------------

normalize_column <- function(column) {
  if (inherits(column, "POSIXt")) {
    return(format(column, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
  }
  if (inherits(column, "Date")) {
    return(format(column, "%Y-%m-%d"))
  }
  if (is.factor(column)) {
    return(as.character(column))
  }
  if (is.list(column)) {
    return(lapply(column, normalize_value))
  }
  column
}

normalize_value <- function(value) {
  if (inherits(value, "POSIXt")) {
    return(format(value, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
  }
  if (inherits(value, "Date")) {
    return(format(value, "%Y-%m-%d"))
  }
  if (is.factor(value)) {
    return(as.character(value))
  }
  if (is.list(value)) {
    return(lapply(value, normalize_value))
  }
  if (is.atomic(value)) {
    return(value)
  }
  as.character(value)
}

serialize_table <- function(result, source_function) {
  ensure_namespace("jsonlite")

  if (!is.data.frame(result)) {
    stop(
      sprintf(
        "%s returned %s instead of a data.frame-like result.",
        source_function,
        paste(class(result), collapse = "/")
      ),
      call. = FALSE
    )
  }

  normalized <- as.data.frame(result, stringsAsFactors = FALSE, check.names = FALSE)
  normalized[] <- lapply(normalized, normalize_column)

  records_json <- jsonlite::toJSON(
    normalized,
    dataframe = "rows",
    auto_unbox = TRUE,
    na = "null",
    null = "null",
    POSIXt = "ISO8601"
  )

  records <- jsonlite::fromJSON(records_json, simplifyVector = FALSE)
  if (is.null(records)) {
    records <- list()
  }

  columns <- lapply(names(normalized), function(column_name) {
    list(
      name  = column_name,
      class = paste(class(result[[column_name]]), collapse = "/")
    )
  })

  list(
    source_function = source_function,
    row_count       = nrow(normalized),
    columns         = columns,
    records         = records
  )
}

call_stock_tool <- function(source_function, expr) {
  ensure_namespace("opendatauzb")

  tryCatch(
    serialize_table(force(expr), source_function = source_function),
    error = function(error) {
      message <- conditionMessage(error)
      prefix  <- sprintf("%s failed:", source_function)

      if (!startsWith(message, prefix)) {
        message <- sprintf("%s %s", prefix, message)
      }

      stop(message, call. = FALSE)
    }
  )
}

# ---------------------------------------------------------------------------
# Tool wrappers
# ---------------------------------------------------------------------------

registered_securities <- function() {
  call_stock_tool("RegisteredSecurities", opendatauzb::RegisteredSecurities())
}

securities <- function() {
  call_stock_tool("getSecurities", opendatauzb::getSecurities())
}

ticker_history <- function(symbols, from = "2020-01-01", to = NULL) {
  normalized_symbols <- normalize_string_array(symbols, "symbols")

  from_iso <- normalize_scalar_string(from, "from")
  validate_iso_date(from_iso, "from")

  to_iso <- resolve_iso_date(to, "to")

  validate_date_range(from_iso, to_iso)

  call_stock_tool(
    "getTicker",
    opendatauzb::getTicker(symbol = normalized_symbols, from = from_iso, to = to_iso)
  )
}

# Upstream getMarketIndex expects DD.MM.YYYY; this wrapper accepts YYYY-MM-DD
# at the MCP boundary and converts before the upstream call.
market_index <- function(sector = "all", from = "2020-01-01", to = NULL) {
  sector <- normalize_scalar_string(sector, "sector", transform = tolower)
  validate_enum(sector, sector_values, "sector")

  from_iso <- normalize_scalar_string(from, "from")
  validate_iso_date(from_iso, "from")

  to_iso <- resolve_iso_date(to, "to")

  validate_date_range(from_iso, to_iso)

  call_stock_tool(
    "getMarketIndex",
    opendatauzb::getMarketIndex(
      sector = sector,
      from   = iso_to_dmy_dot(from_iso),
      to     = iso_to_dmy_dot(to_iso)
    )
  )
}

current_bids_asks <- function(security_code = "", security_type = "STK") {
  security_code <- normalize_scalar_string(
    security_code, "security_code", default = "", allow_empty = TRUE
  )
  security_type <- normalize_scalar_string(security_type, "security_type", transform = toupper)
  validate_enum(security_type, security_type_values, "security_type")

  call_stock_tool(
    "currentBidsAsks",
    opendatauzb::currentBidsAsks(
      security_code = security_code,
      security_type = security_type
    )
  )
}

ipo_calendar <- function(search_key = "", plus_n_years = 1L) {
  search_key <- normalize_scalar_string(
    search_key, "search_key", default = "", allow_empty = TRUE
  )

  if (is.null(plus_n_years) || length(plus_n_years) != 1 || is.na(plus_n_years)) {
    stop("`plus_n_years` must be a single number.", call. = FALSE)
  }

  call_stock_tool(
    "ipo",
    opendatauzb::ipo(key = search_key, plus_n_years = as.numeric(plus_n_years))
  )
}

# Upstream get_FX expects DD-MM-YYYY; this wrapper accepts YYYY-MM-DD at the
# MCP boundary and converts before the upstream call.
fx_rates <- function(currency = "USD", from = "2022-01-01", to = NULL) {
  currency <- normalize_scalar_string(currency, "currency", transform = toupper)
  validate_enum(currency, fx_currency_values, "currency")

  from_iso <- normalize_scalar_string(from, "from")
  validate_iso_date(from_iso, "from")

  to_iso <- resolve_iso_date(to, "to")

  validate_date_range(from_iso, to_iso)

  call_stock_tool(
    "get_FX",
    opendatauzb::get_FX(
      currency = currency,
      from     = iso_to_dmy_dash(from_iso),
      to       = iso_to_dmy_dash(to_iso)
    )
  )
}

all_issuers <- function() {
  call_stock_tool("getAllIssuers", opendatauzb::getAllIssuers())
}

dividends <- function(stock_type = "all") {
  stock_type <- normalize_scalar_string(stock_type, "stock_type", transform = tolower)
  validate_enum(stock_type, dividend_type_values, "stock_type")

  upstream_stock_type <- if (identical(stock_type, "all")) "" else stock_type

  call_stock_tool(
    "getDividends",
    opendatauzb::getDividends(stockType = upstream_stock_type)
  )
}
