# file_logger.R - File Logging Module
#
# Simple, reliable file logging utility with no external dependencies

# Create environment to store file logger configuration
if (!exists("file_logger_env", envir = .GlobalEnv)) {
  assign("file_logger_env", new.env(), envir = .GlobalEnv)
  file_logger_env$log_file <- "application.log"
  file_logger_env$log_to_console <- FALSE
  file_logger_env$initialized <- FALSE
  file_logger_env$log_level <- "INFO"  # Default level
}

# Define log levels and their hierarchy
LOG_LEVELS <- list(
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4
)

#' Initialize the file logger with a specific log file
#' 
#' @param log_file Path to the log file
#' @param append Whether to append to an existing log file or create a new one
#' @param log_to_console Whether to also log messages to the console
#' @param level Minimum log level to record (DEBUG, INFO, WARN, ERROR)
#' @return Invisibly returns TRUE on success
initialize_file_logger <- function(log_file = "application.log", 
                                   append = TRUE, 
                                   log_to_console = FALSE,
                                   level = "INFO") {
  
  # Validate log level
  level <- toupper(level)
  if (!level %in% names(LOG_LEVELS)) {
    warning("Invalid log level specified. Using INFO as default.")
    level <- "INFO"
  }
  
  # Store configuration in environment
  file_logger_env$log_file <- log_file
  file_logger_env$log_to_console <- log_to_console
  file_logger_env$log_level <- level
  
  # Create parent directory if it doesn't exist
  log_dir <- dirname(log_file)
  if (!dir.exists(log_dir) && log_dir != ".") {
    dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Create or clear the log file if not appending
  if (!append) {
    tryCatch({
      file.create(log_file, showWarnings = FALSE)
    }, error = function(e) {
      warning(paste("Could not create log file:", e$message))
    })
  }
  
  # Write header to log file
  log_entry <- paste0(
    "==========================================================\n",
    "Log started at ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n",
    "R version: ", R.version$version.string, "\n",
    "Platform: ", R.version$platform, "\n",
    "Working directory: ", getwd(), "\n",
    "Log level: ", level, "\n",
    "==========================================================\n"
  )
  
  tryCatch({
    cat(log_entry, file = log_file, append = append)
    file_logger_env$initialized <- TRUE
  }, error = function(e) {
    warning(paste("Could not write to log file:", e$message))
    file_logger_env$initialized <- FALSE
  })
  
  return(invisible(file_logger_env$initialized))
}

#' Internal function to write a log entry to file
#' 
#' @param level The log level (INFO, WARN, ERROR, DEBUG)
#' @param message The message to log
#' @return Invisibly returns TRUE on success
log_to_file <- function(level, message) {
  if (!file_logger_env$initialized) {
    # Initialize with defaults if not already initialized
    initialize_file_logger()
  }
  
  level <- toupper(level)
  
  # Check if we should log this level
  if (LOG_LEVELS[[level]] < LOG_LEVELS[[file_logger_env$log_level]]) {
    return(invisible(FALSE))
  }
  
  # Get configuration from environment
  log_file <- file_logger_env$log_file
  log_to_console <- file_logger_env$log_to_console
  
  # Format the log entry
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- sprintf("[%s] [%s] %s\n", timestamp, level, message)
  
  # Write to log file
  success <- tryCatch({
    cat(log_entry, file = log_file, append = TRUE)
    TRUE
  }, error = function(e) {
    # If we can't write to the log file, output to console regardless of setting
    cat("Error writing to log file:", e$message, "\n")
    cat(log_entry)
    FALSE
  })
  
  # Also log to console if configured
  if (log_to_console && success) {
    cat(log_entry)
  }
  
  return(invisible(success))
}

#' Log a debug message
#' 
#' @param message The message to log
#' @return Invisibly returns TRUE on success
log_debug <- function(message) {
  log_to_file("DEBUG", message)
}

#' Log an informational message
#' 
#' @param message The message to log
#' @return Invisibly returns TRUE on success
log_info <- function(message) {
  log_to_file("INFO", message)
}

#' Log a warning message
#' 
#' @param message The message to log
#' @return Invisibly returns TRUE on success
log_warn <- function(message) {
  log_to_file("WARN", message)
}

#' Log an error message
#' 
#' @param message The message to log
#' @return Invisibly returns TRUE on success
log_error <- function(message) {
  log_to_file("ERROR", message)
}

#' Set whether to also log messages to the console
#' 
#' @param enabled TRUE to enable console logging, FALSE to disable
#' @return Invisibly returns the previous setting
set_console_logging <- function(enabled = TRUE) {
  previous <- file_logger_env$log_to_console
  file_logger_env$log_to_console <- enabled
  return(invisible(previous))
}

#' Change the log file
#' 
#' @param log_file Path to the new log file
#' @param append Whether to append to an existing log file or create a new one
#' @return Invisibly returns the previous log file path
set_log_file <- function(log_file, append = TRUE) {
  previous <- file_logger_env$log_file
  file_logger_env$log_file <- log_file
  
  # Create or clear the log file if not appending
  if (!append) {
    tryCatch({
      file.create(log_file, showWarnings = FALSE)
    }, error = function(e) {
      warning(paste("Could not create log file:", e$message))
    })
  }
  
  return(invisible(previous))
}

#' Set the minimum log level 
#' 
#' @param level New minimum log level (DEBUG, INFO, WARN, ERROR)
#' @return Invisibly returns the previous log level
set_log_level <- function(level) {
  level <- toupper(level)
  if (!level %in% names(LOG_LEVELS)) {
    warning("Invalid log level specified. Not changing current level.")
    return(invisible(file_logger_env$log_level))
  }
  
  previous <- file_logger_env$log_level
  file_logger_env$log_level <- level
  
  return(invisible(previous))
}