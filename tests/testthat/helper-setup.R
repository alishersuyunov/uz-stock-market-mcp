root_dir <- Sys.getenv("UZ_STOCK_MCP_ROOT", unset = "")
if (!nzchar(root_dir)) {
  stop("UZ_STOCK_MCP_ROOT must be set before running the tests.", call. = FALSE)
}

source(file.path(root_dir, "R", "wrappers.R"), local = globalenv(), chdir = FALSE)

load_mcp_tools <- function() {
  env <- new.env(parent = globalenv())
  source(file.path(root_dir, "R", "mcp-tools.R"), local = env, chdir = FALSE)
  get("tool_definitions", envir = env, inherits = FALSE)
}
