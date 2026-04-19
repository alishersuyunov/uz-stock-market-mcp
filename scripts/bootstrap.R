find_script_path <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- "--file="
  matches <- grep(file_arg, args, value = TRUE)

  if (length(matches) == 0) {
    stop("Unable to determine the path to scripts/bootstrap.R.", call. = FALSE)
  }

  normalizePath(sub(file_arg, "", matches[[1]]), winslash = "/", mustWork = TRUE)
}

is_true_env <- function(name) {
  identical(tolower(Sys.getenv(name, unset = "false")), "true")
}

configure_user_library <- function(project_root) {
  user_library <- file.path(project_root, ".r-library")
  dir.create(user_library, recursive = TRUE, showWarnings = FALSE)
  user_library <- normalizePath(user_library, winslash = "/", mustWork = TRUE)
  Sys.setenv(R_LIBS_USER = user_library)
  system_libraries <- unique(c(.Library.site, .Library))
  system_libraries <- system_libraries[nzchar(system_libraries)]
  .libPaths(c(user_library, system_libraries))
  user_library
}

package_is_usable <- function(package_name) {
  tryCatch(
    {
      loadNamespace(package_name)
      TRUE
    },
    error = function(error) FALSE
  )
}

install_if_missing <- function(package_name, repos, library_path) {
  installed <- rownames(installed.packages(lib.loc = library_path))
  if (package_name %in% installed && package_is_usable(package_name)) {
    message(sprintf("Package '%s' is already installed and loadable in %s.", package_name, library_path))
    return(invisible(FALSE))
  }

  message(sprintf("Installing CRAN package '%s'...", package_name))
  install.packages(
    package_name,
    repos = repos,
    lib = library_path,
    dependencies = c("Depends", "Imports", "LinkingTo")
  )
  invisible(TRUE)
}

project_root <- dirname(dirname(find_script_path()))
library_path <- configure_user_library(project_root)
Sys.setenv(UZ_STOCK_MCP_ROOT = project_root)

cran_repo <- Sys.getenv("R_CRAN_REPO", unset = "https://cloud.r-project.org")
options(repos = c(CRAN = cran_repo))

cran_packages <- c("remotes", "mcptools", "ellmer", "testthat", "rlist")
for (package_name in cran_packages) {
  install_if_missing(package_name, repos = cran_repo, library_path = library_path)
}

if (!requireNamespace("remotes", quietly = TRUE)) {
  stop("Package 'remotes' is required after bootstrap but could not be loaded.", call. = FALSE)
}

source_override <- Sys.getenv("OPENDATAUZB_SRC", unset = "")
reinstall_requested <- is_true_env("OPENDATAUZB_REINSTALL")
opendatauzb_installed <- "opendatauzb" %in% rownames(installed.packages(lib.loc = library_path))
opendatauzb_usable <- package_is_usable("opendatauzb")
opendatauzb_force_install <- reinstall_requested || !opendatauzb_usable

if (nzchar(source_override)) {
  source_override <- normalizePath(source_override, winslash = "/", mustWork = TRUE)
  message(sprintf("Installing 'opendatauzb' from local source: %s", source_override))
  remotes::install_local(
    source_override,
    upgrade = "never",
    dependencies = c("Depends", "Imports", "LinkingTo"),
    force = TRUE,
    lib = library_path
  )
} else if (!opendatauzb_installed || !opendatauzb_usable || reinstall_requested) {
  message("Installing 'opendatauzb' from GitHub: alishersuyunov/opendatauzb")
  remotes::install_github(
    "alishersuyunov/opendatauzb",
    upgrade = "never",
    dependencies = c("Depends", "Imports", "LinkingTo"),
    force = opendatauzb_force_install,
    lib = library_path
  )
} else {
  message("Package 'opendatauzb' is already installed and loadable in the repo-local library. Set OPENDATAUZB_REINSTALL=true to reinstall from GitHub.")
}

message("Bootstrap complete.")
