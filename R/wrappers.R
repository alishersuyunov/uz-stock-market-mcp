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
      name = column_name,
      class = paste(class(result[[column_name]]), collapse = "/")
    )
  })

  list(
    source_function = source_function,
    row_count = nrow(normalized),
    columns = columns,
    records = records
  )
}

call_stock_tool <- function(source_function, expr) {
  ensure_namespace("opendatauzb")

  tryCatch(
    serialize_table(force(expr), source_function = source_function),
    error = function(error) {
      message <- conditionMessage(error)
      prefix <- sprintf("%s failed:", source_function)

      if (!startsWith(message, prefix)) {
        message <- sprintf("%s %s", prefix, message)
      }

      stop(message, call. = FALSE)
    }
  )
}

registered_securities <- function() {
  call_stock_tool(
    "RegisteredSecurities",
    opendatauzb::RegisteredSecurities()
  )
}

securities <- function() {
  call_stock_tool(
    "getSecurities",
    opendatauzb::getSecurities()
  )
}

ticker_history <- function(symbols, from = "2020-01-01", to = "yyyy-mm-dd") {
  normalized_symbols <- normalize_string_array(symbols, "symbols")
  from <- normalize_scalar_string(from, "from")
  to <- normalize_scalar_string(to, "to")

  call_stock_tool(
    "getTicker",
    opendatauzb::getTicker(
      symbol = normalized_symbols,
      from = from,
      to = to
    )
  )
}

market_index <- function(
  sector = "all",
  from = "01.01.2020",
  to = "dd.mm.yyyy"
) {
  sector <- normalize_scalar_string(
    sector,
    "sector",
    transform = tolower
  )
  from <- normalize_scalar_string(from, "from")
  to <- normalize_scalar_string(to, "to")

  call_stock_tool(
    "getMarketIndex",
    opendatauzb::getMarketIndex(
      sector = sector,
      from = from,
      to = to
    )
  )
}

current_bids_asks <- function(security_code = "", security_type = "STK") {
  security_code <- normalize_scalar_string(
    security_code,
    "security_code",
    default = "",
    allow_empty = TRUE
  )
  security_type <- normalize_scalar_string(
    security_type,
    "security_type",
    transform = toupper
  )

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
    search_key,
    "search_key",
    default = "",
    allow_empty = TRUE
  )

  if (is.null(plus_n_years) || length(plus_n_years) != 1 || is.na(plus_n_years)) {
    stop("`plus_n_years` must be a single number.", call. = FALSE)
  }

  call_stock_tool(
    "ipo",
    opendatauzb::ipo(
      key = search_key,
      plus_n_years = as.numeric(plus_n_years)
    )
  )
}

fx_rates <- function(currency = "USD", from = "01-01-2022", to = "dd-mm-YYYY") {
  currency <- normalize_scalar_string(
    currency,
    "currency",
    transform = toupper
  )
  from <- normalize_scalar_string(from, "from")
  to <- normalize_scalar_string(to, "to")

  call_stock_tool(
    "get_FX",
    opendatauzb::get_FX(
      currency = currency,
      from = from,
      to = to
    )
  )
}

all_issuers <- function() {
  call_stock_tool(
    "getAllIssuers",
    opendatauzb::getAllIssuers()
  )
}

dividends <- function(stock_type = "all") {
  stock_type <- normalize_scalar_string(
    stock_type,
    "stock_type",
    transform = tolower
  )

  upstream_stock_type <- if (identical(stock_type, "all")) "" else stock_type

  call_stock_tool(
    "getDividends",
    opendatauzb::getDividends(stockType = upstream_stock_type)
  )
}
