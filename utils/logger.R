# logger.R - Combined Logging Module
#
# This module combines file and syslog logging capabilities

# Source the individual logging modules
source("utils/file_logger.R")
source("utils/system_syslog.R")

#' Initialize logging with both file and syslog support
#' 
#' @param log_file Path to the log file (NULL to disable file logging)
#' @param syslog_host Syslog server host (NULL to disable syslog)
#' @param syslog_port Syslog server port
#' @param level Minimum log level to record (DEBUG, INFO, WARN, ERROR)
#' @param app_name Application name for syslog
#' @return Invisibly returns TRUE if at least one logger was initialized
initialize_logger <- function(log_file = "application.log", 
                              syslog_host = NULL,
                              syslog_port = 514,
                              level = "INFO",
                              app_name = "r-application") {
  
  file_success <- FALSE
  syslog_success <- FALSE
  
  # Initialize file logger if requested
  if (!is.null(log_file)) {
    file_success <- initialize_file_logger(log_file, append = TRUE, 
                                           log_to_console = FALSE, 
                                           level = level)
  }
  
  # Initialize syslog if requested
  if (!is.null(syslog_host)) {
    syslog_success <- initialize_syslog(host = syslog_host, 
                                        port = syslog_port, 
                                        facility = 1, 
                                        app_name = app_name,
                                        level = level)
  }
  
  return(invisible(file_success || syslog_success))
}

#' Log a debug message to all enabled logging systems
#' 
#' @param message The message to log
#' @return Invisibly returns TRUE on success
log_debug <- function(message) {
  success <- TRUE
  
  # Log to file if initialized
  if (exists("file_logger_env", envir = .GlobalEnv) && file_logger_env$initialized) {
    success <- success && log_to_file("DEBUG", message)
  }
  
  # Log to syslog if enabled
  if (exists("syslog_env", envir = .GlobalEnv) && syslog_env$enabled) {
    success <- success && send_to_syslog("DEBUG", message)
  }
  
  return(invisible(success))
}

#' Log an informational message to all enabled logging systems
#' 
#' @param message The message to log
#' @return Invisibly returns TRUE on success
log_info <- function(message) {
  success <- TRUE
  
  # Log to file if initialized
  if (exists("file_logger_env", envir = .GlobalEnv) && file_logger_env$initialized) {
    success <- success && log_to_file("INFO", message)
  }
  
  # Log to syslog if enabled
  if (exists("syslog_env", envir = .GlobalEnv) && syslog_env$enabled) {
    success <- success && send_to_syslog("INFO", message)
  }
  
  return(invisible(success))
}

#' Log a warning message to all enabled logging systems
#' 
#' @param message The message to log
#' @return Invisibly returns TRUE on success
log_warn <- function(message) {
  success <- TRUE
  
  # Log to file if initialized
  if (exists("file_logger_env", envir = .GlobalEnv) && file_logger_env$initialized) {
    success <- success && log_to_file("WARN", message)
  }
  
  # Log to syslog if enabled
  if (exists("syslog_env", envir = .GlobalEnv) && syslog_env$enabled) {
    success <- success && send_to_syslog("WARN", message)
  }
  
  return(invisible(success))
}

#' Log an error message to all enabled logging systems
#' 
#' @param message The message to log
#' @return Invisibly returns TRUE on success
log_error <- function(message) {
  success <- TRUE
  
  # Log to file if initialized
  if (exists("file_logger_env", envir = .GlobalEnv) && file_logger_env$initialized) {
    success <- success && log_to_file("ERROR", message)
  }
  
  # Log to syslog if enabled
  if (exists("syslog_env", envir = .GlobalEnv) && syslog_env$enabled) {
    success <- success && send_to_syslog("ERROR", message)
  }
  
  return(invisible(success))
}

#' Close all logging connections
#' 
#' @return Invisibly returns TRUE if all connections closed successfully
close_logger <- function() {
  success <- TRUE
  
  # Close syslog if enabled
  if (exists("syslog_env", envir = .GlobalEnv) && syslog_env$enabled) {
    success <- success && close_syslog()
  }
  
  return(invisible(success))
}

#' Set the minimum log level for all loggers
#' 
#' @param level New minimum log level (DEBUG, INFO, WARN, ERROR)
#' @return Invisibly returns TRUE if successful
set_log_level <- function(level) {
  success <- TRUE
  
  # Set file logger level if initialized
  if (exists("file_logger_env", envir = .GlobalEnv) && file_logger_env$initialized) {
    set_log_level(level)
  }
  
  # Set syslog level if enabled
  if (exists("syslog_env", envir = .GlobalEnv) && syslog_env$enabled) {
    set_syslog_level(level)
  }
  
  return(invisible(success))
}