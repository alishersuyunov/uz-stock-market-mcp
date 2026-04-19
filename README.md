# Uzbekistan Stock Market MCP in R

This repository provides a standalone R MCP server for Uzbekistan stock market data. It uses [`mcptools`](https://cran.r-project.org/web/packages/mcptools/vignettes/server.html) with custom `ellmer::tool()` definitions backed by the upstream [`alishersuyunov/opendatauzb`](https://github.com/alishersuyunov/opendatauzb) package.

## Scope

The server exposes these stock-market tools:

- `registered_securities`
- `securities`
- `ticker_history`
- `market_index`
- `current_bids_asks`
- `ipo_calendar`
- `fx_rates`
- `all_issuers`
- `dividends`

## Bootstrap

Install the MCP dependencies and `opendatauzb`:

```powershell
Rscript .\scripts\bootstrap.R
```

Bootstrap installs `opendatauzb` from GitHub by default.

To use a local checkout instead, set `OPENDATAUZB_SRC` before running bootstrap:

```powershell
$env:OPENDATAUZB_SRC = "<path-to-local-opendatauzb-checkout>"
Rscript .\scripts\bootstrap.R
```

To force a reinstall from GitHub:

```powershell
$env:OPENDATAUZB_REINSTALL = "true"
Rscript .\scripts\bootstrap.R
```

## Run the Server

Start the server with:

```powershell
Rscript .\run-mcp.R
```

The server uses stdio transport and does not expose `mcptools` session tools.

## Claude Code Setup

Example `claude mcp add` command:

```powershell
claude mcp add -s user uz-stock-market-r -- "Rscript" "<path-to-this-repo>\\run-mcp.R"
```

If `Rscript` is not on `PATH`, replace `Rscript` with the full path to `Rscript.exe`.

## Tests

Run the smoke tests with:

```powershell
Rscript .\scripts\test.R
```

The smoke tests verify tool registration, JSON-safe table envelopes, multiple-symbol ticker history, and concise date validation errors.
