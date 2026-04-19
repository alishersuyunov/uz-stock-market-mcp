find_script_path <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- "--file="
  matches <- grep(file_arg, args, value = TRUE)

  if (length(matches) == 0) {
    stop("Unable to determine the path to scripts/test.R.", call. = FALSE)
  }

  normalizePath(sub(file_arg, "", matches[[1]]), winslash = "/", mustWork = TRUE)
}

configure_user_library <- function(project_root) {
  user_library <- file.path(project_root, ".r-library")
  dir.create(user_library, recursive = TRUE, showWarnings = FALSE)
  user_library <- normalizePath(user_library, winslash = "/", mustWork = TRUE)
  Sys.setenv(R_LIBS_USER = user_library)
  system_libraries <- unique(c(.Library.site, .Library))
  system_libraries <- system_libraries[nzchar(system_libraries)]
  .libPaths(c(user_library, system_libraries))
}

project_root <- dirname(dirname(find_script_path()))
configure_user_library(project_root)
Sys.setenv(UZ_STOCK_MCP_ROOT = project_root)

if (!requireNamespace("testthat", quietly = TRUE)) {
  stop("Missing required package 'testthat'. Run scripts/bootstrap.R first.", call. = FALSE)
}

testthat::test_dir(
  file.path(project_root, "tests", "testthat"),
  reporter = "summary",
  stop_on_failure = TRUE
)
