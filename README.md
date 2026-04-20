# uz-stock-market-mcp

An R MCP server that gives LLM agents structured access to Uzbekistan stock market data. Connect it to Claude Desktop, Claude Code, or any MCP-compatible host and ask natural-language questions about securities, prices, the market index, exchange rates, dividends, and IPOs — the server translates those requests into calls to the [`opendatauzb`](https://github.com/alishersuyunov/opendatauzb) package and returns clean, JSON-serializable envelopes ready for the model to reason over.

## Scope

The server wraps the Republican Stock Exchange Toshkent (RSE) and Central Securities Depository (CSD) data exposed by `opendatauzb`. It does not cover exchanges outside Uzbekistan and does not provide order execution or account access of any kind.

## Tool catalog

| Tool | Purpose | Key parameters | Return shape |
|---|---|---|---|
| `registered_securities` | All securities registered with the CSD | — | Registered security records |
| `securities` | Securities listed on RSE Toshkent | — | `Type`, `SecurityCode`, `Ticker`, `Issuer` per row |
| `ticker_history` | Historical prices for one or more tickers | `symbols` (required), `from`, `to` (YYYY-MM-DD) | Price/volume records per symbol |
| `market_index` | Uzbekistan Composite Index by sector and date range | `sector` (enum), `from`, `to` (YYYY-MM-DD) | Index value records |
| `current_bids_asks` | Live order book snapshot | `security_code` (optional), `security_type` (STK \| BND \| RPO \| FCT) | Bid/ask records |
| `ipo_calendar` | Public offering schedule | `search_key` (optional), `plus_n_years` | IPO event records |
| `fx_rates` | UZS exchange rate history vs USD or EUR | `currency` (USD \| EUR), `from`, `to` (YYYY-MM-DD) | Date/rate records |
| `all_issuers` | Full issuer list from the CSD | — | Issuer records |
| `dividends` | Dividend calendar | `stock_type` (all \| privileged \| simple \| bond) | Dividend event records |

All date parameters accept **YYYY-MM-DD** only. `from` and `to` are optional on date-range tools and default to a historical start date and today respectively.

Every tool returns an envelope:

```json
{
  "source_function": "<upstream function name>",
  "row_count": 42,
  "columns": [{"name": "ColumnName", "class": "character"}, ...],
  "records": [{...}, ...]
}
```

## Data freshness

This server is a thin client wrapper. It does not cache results. Each tool call queries the upstream `opendatauzb` functions, which in turn call RSE and CSD APIs. Data freshness depends entirely on how often those sources update, which is outside the control of this server. Do not assume real-time or intraday data unless the upstream exchange documentation confirms it.

## Quickstart

### 1. Bootstrap (install dependencies)

macOS / Linux:
```bash
Rscript scripts/bootstrap.R
```

Windows (PowerShell or cmd):
```bat
Rscript scripts\bootstrap.R
```

Bootstrap installs `mcptools`, `ellmer`, `testthat`, and `opendatauzb` (from GitHub) into a project-local `.r-library/` directory so it does not pollute your system library.

To use a local `opendatauzb` checkout instead of GitHub:

```bash
OPENDATAUZB_SRC=/path/to/opendatauzb Rscript scripts/bootstrap.R
```

Windows (PowerShell):
```powershell
$env:OPENDATAUZB_SRC = "C:\path\to\opendatauzb"
Rscript scripts\bootstrap.R
```

To force a reinstall from GitHub:

```bash
OPENDATAUZB_REINSTALL=true Rscript scripts/bootstrap.R
```

### 2. Run the server

macOS / Linux:
```bash
Rscript run-mcp.R
```

Windows:
```bat
Rscript run-mcp.R
```

The server speaks the MCP stdio protocol. It does not expose session tools.

### 3. Run the tests

macOS / Linux:
```bash
Rscript scripts/test.R
```

Windows:
```bat
Rscript scripts\test.R
```

Tests are split into two groups: validation and transformation tests (no network required) and contract tests (require `opendatauzb` and a live connection). The latter are skipped automatically if `opendatauzb` is not installed.

## MCP client configuration

### Claude Code

```bash
claude mcp add -s user uz-stock-market-r -- Rscript /path/to/uz-stock-market-mcp/run-mcp.R
```

Windows — use the full path with backslashes or quotes if the path contains spaces:
```bat
claude mcp add -s user uz-stock-market-r -- Rscript "C:\path\to\uz-stock-market-mcp\run-mcp.R"
```

### Claude Desktop (`claude_desktop_config.json`)

```json
{
  "mcpServers": {
    "uz-stock-market": {
      "command": "Rscript",
      "args": ["/path/to/uz-stock-market-mcp/run-mcp.R"]
    }
  }
}
```

Windows path variant:
```json
{
  "mcpServers": {
    "uz-stock-market": {
      "command": "Rscript",
      "args": ["C:\\path\\to\\uz-stock-market-mcp\\run-mcp.R"]
    }
  }
}
```

If `Rscript` is not on your `PATH`, replace `"Rscript"` with the full path to the executable (e.g. `"C:\\Program Files\\R\\R-4.4.0\\bin\\Rscript.exe"`).

## Example prompts

Once connected, an LLM can answer questions like:

- "What securities are currently listed on the Uzbek stock exchange?"
- "Show me the price history for KVTS and UZTL from January to June 2024."
- "What is the Uzbekistan Composite Index for the finance sector this year?"
- "What is today's USD/UZS exchange rate history for the past 6 months?"
- "List upcoming IPOs on the Uzbek market."
- "Which companies have paid dividends this year?"
- "Show me the current bids and asks for bonds."

## Example JSON output

### `securities`

```json
{
  "source_function": "getSecurities",
  "row_count": 2,
  "columns": [
    {"name": "Type",         "class": "character"},
    {"name": "SecurityCode", "class": "character"},
    {"name": "Ticker",       "class": "character"},
    {"name": "Issuer",       "class": "character"}
  ],
  "records": [
    {"Type": "STK", "SecurityCode": "UZ7025770007", "Ticker": "KVTS", "Issuer": "Kvarts"},
    {"Type": "STK", "SecurityCode": "UZ7047110000", "Ticker": "UZTL", "Issuer": "Uzbektelecom"}
  ]
}
```

### `market_index` (illustrative; actual field names reflect the upstream source)

```json
{
  "source_function": "getMarketIndex",
  "row_count": 3,
  "columns": [
    {"name": "Date",  "class": "Date"},
    {"name": "Index", "class": "numeric"}
  ],
  "records": [
    {"Date": "2024-01-02", "Index": 1023.45},
    {"Date": "2024-01-03", "Index": 1028.12},
    {"Date": "2024-01-04", "Index": 1019.67}
  ]
}
```

### `fx_rates` (illustrative; actual field names reflect the upstream source)

```json
{
  "source_function": "get_FX",
  "row_count": 2,
  "columns": [
    {"name": "Date",     "class": "Date"},
    {"name": "Currency", "class": "character"},
    {"name": "Rate",     "class": "numeric"}
  ],
  "records": [
    {"Date": "2024-01-02", "Currency": "USD", "Rate": 12650.0},
    {"Date": "2024-01-03", "Currency": "USD", "Rate": 12655.5}
  ]
}
```

> **Note:** Field names inside `records` depend entirely on the upstream `opendatauzb` package. The envelope keys (`source_function`, `row_count`, `columns`, `records`) are stable.

## Development notes

```
uz-stock-market-mcp/
├── run-mcp.R              # Entry point — locates project root, starts stdio server
├── R/
│   ├── wrappers.R         # Validation helpers, date conversion, tool wrapper functions
│   └── mcp-tools.R        # ellmer tool definitions sourced by mcptools at runtime
├── scripts/
│   ├── bootstrap.R        # Installs all dependencies into .r-library/
│   └── test.R             # Runs testthat suite
└── tests/testthat/
    ├── helper-setup.R     # Sources wrappers.R; provides load_mcp_tools()
    ├── test-tools.R       # Verifies tool registration and names
    └── test-wrappers.R    # Validation, transformation, and contract tests
```

**Date handling:** `market_index` and `fx_rates` accept YYYY-MM-DD at the MCP boundary and convert to the format their respective upstream functions expect (DD.MM.YYYY and DD-MM-YYYY). `ticker_history` passes ISO dates through unchanged because the upstream already accepts them.

**Enum constants** (`sector_values`, `security_type_values`, etc.) are defined once in `wrappers.R` and reused in both validation code and `mcp-tools.R` tool definitions.

**Transport:** stdio only. Do not add HTTP transport without carefully reviewing the security implications.

## Troubleshooting

**`Rscript` not found**
Add the R `bin/` directory to your `PATH`, or use the full path to `Rscript` / `Rscript.exe` in all commands.

**`Missing required package 'mcptools'`**
Run `Rscript scripts/bootstrap.R`. The server uses a project-local library (`.r-library/`) and will not find system-installed packages unless bootstrap has been run from the same project root.

**`UZ_STOCK_MCP_ROOT is not set`**
Always start the server via `Rscript run-mcp.R` rather than sourcing `R/mcp-tools.R` directly. The entry point sets the environment variable that the rest of the code depends on.

**`opendatauzb` fails to install**
GitHub installation requires `remotes`. Bootstrap installs it from CRAN first. If you are behind a corporate proxy, set `https_proxy` before running bootstrap. You can also point to a local checkout via `OPENDATAUZB_SRC`.

**Tests fail with connection errors**
Contract tests (those that call `opendatauzb` functions) require a live internet connection to the RSE/CSD APIs. Validation and transformation tests pass without a connection and without `opendatauzb` installed.
