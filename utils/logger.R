# syslog_logger.R - Syslog Logging Module
#
# Functions for logging to syslog via UDP

# Create environment to store syslog configuration
if (!exists("syslog_env", envir = .GlobalEnv)) {
  assign("syslog_env", new.env(), envir = .GlobalEnv)
  syslog_env$enabled <- FALSE
  syslog_env$connection <- NULL
  syslog_env$facility <- 1  # user-level messages (default)
  syslog_env$hostname <- Sys.info()["nodename"]
  syslog_env$app_name <- "r-application"
  syslog_env$log_level <- "INFO"  # Default level
}

# Define log levels and their hierarchy
SYSLOG_LOG_LEVELS <- list(
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4
)

# Syslog severity levels
SYSLOG_SEVERITY <- list(
  EMERG = 0,    # system is unusable
  ALERT = 1,    # action must be taken immediately
  CRIT = 2,     # critical conditions
  ERR = 3,      # error conditions
  WARNING = 4,  # warning conditions
  NOTICE = 5,   # normal but significant condition
  INFO = 6,     # informational messages
  DEBUG = 7     # debug-level messages
)

# Map our log levels to syslog severity
map_level_to_severity <- function(level) {
  switch(toupper(level),
         "ERROR" = SYSLOG_SEVERITY$ERR,
         "WARN" = SYSLOG_SEVERITY$WARNING,
         "INFO" = SYSLOG_SEVERITY$INFO,
         "DEBUG" = SYSLOG_SEVERITY$DEBUG,
         SYSLOG_SEVERITY$NOTICE)  # default
}

#' Initialize syslog connection
#' 
#' @param host Syslog server host
#' @param port Syslog server port
#' @param facility Syslog facility code (0-23)
#' @param app_name Application name to appear in syslog
#' @param level Minimum log level to record (DEBUG, INFO, WARN, ERROR)
#' @param rfc5424 Whether to use RFC5424 format (TRUE) or RFC3164 format (FALSE)
#' @return TRUE if connection successful, FALSE otherwise
initialize_syslog <- function(host = "127.0.0.1", 
                              port = 514, 
                              facility = 1, 
                              app_name = "r-application",
                              level = "INFO",
                              rfc5424 = TRUE) {
  
  # Validate log level
  level <- toupper(level)
  if (!level %in% names(SYSLOG_LOG_LEVELS)) {
    warning("Invalid log level specified. Using INFO as default.")
    level <- "INFO"
  }
  
  tryCatch({
    # Close any existing connection
    if (!is.null(syslog_env$connection) && isOpen(syslog_env$connection)) {
      close(syslog_env$connection)
    }
    
    # Create a new UDP connection
    conn <- socketConnection(
      host = host,
      port = port,
      server = FALSE,
      blocking = FALSE,
      open = "w",
      udp = TRUE
    )
    
    syslog_env$connection <- conn
    syslog_env$enabled <- TRUE
    syslog_env$facility <- facility
    syslog_env$app_name <- app_name
    syslog_env$hostname <- Sys.info()["nodename"]
    syslog_env$rfc5424 <- rfc5424
    syslog_env$log_level <- level
    
    # Log a test message
    message <- paste("Syslog connection initialized for", app_name)
    syslog_info(message)
    
    return(TRUE)
  }, error = function(e) {
    warning(paste("Failed to initialize syslog connection:", e$message))
    syslog_env$enabled <- FALSE
    return(FALSE)
  })
}

#' Close syslog connection
#' 
#' @return TRUE if closed successfully, FALSE otherwise
close_syslog <- function() {
  if (!is.null(syslog_env$connection) && isOpen(syslog_env$connection)) {
    tryCatch({
      close(syslog_env$connection)
      syslog_env$enabled <- FALSE
      return(TRUE)
    }, error = function(e) {
      warning(paste("Failed to close syslog connection:", e$message))
      return(FALSE)
    })
  }
  return(TRUE)
}

#' Send a message to syslog
#' 
#' @param level Log level
#' @param message Message to log
#' @return TRUE if sent successfully, FALSE otherwise
send_to_syslog <- function(level, message) {
  if (!syslog_env$enabled || is.null(syslog_env$connection) || !isOpen(syslog_env$connection)) {
    return(FALSE)
  }
  
  level <- toupper(level)
  
  # Check if we should log this level
  if (SYSLOG_LOG_LEVELS[[level]] < SYSLOG_LOG_LEVELS[[syslog_env$log_level]]) {
    return(invisible(FALSE))
  }
  
  severity <- map_level_to_severity(level)
  
  # Calculate PRI value: (facility * 8) + severity
  pri <- (syslog_env$facility * 8) + severity
  
  # Format the syslog message based on preferred format
  if (syslog_env$rfc5424) {
    # RFC5424 format
    timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
    hostname <- syslog_env$hostname
    app_name <- syslog_env$app_name
    proc_id <- Sys.getpid()
    msg_id <- "-"
    
    syslog_msg <- sprintf("<%d>1 %s %s %s %s %s - %s", 
                          pri, timestamp, hostname, app_name, 
                          proc_id, msg_id, message)
  } else {
    # RFC3164 (BSD) format
    timestamp <- format(Sys.time(), "%b %e %H:%M:%S")
    hostname <- syslog_env$hostname
    app_name <- syslog_env$app_name
    
    syslog_msg <- sprintf("<%d>%s %s %s[%d]: %s", 
                          pri, timestamp, hostname, app_name, 
                          Sys.getpid(), message)
  }
  
  tryCatch({
    writeLines(syslog_msg, syslog_env$connection)
    return(TRUE)
  }, error = function(e) {
    warning(paste("Failed to send message to syslog:", e$message))
    return(FALSE)
  })
}

#' Log a debug message to syslog
#' 
#' @param message The message to log
#' @return Invisibly returns TRUE on success
syslog_debug <- function(message) {
  send_to_syslog("DEBUG", message)
}

#' Log an informational message to syslog
#' 
#' @param message The message to log
#' @return Invisibly returns TRUE on success
syslog_info <- function(message) {
  send_to_syslog("INFO", message)
}

#' Log a warning message to syslog
#' 
#' @param message The message to log
#' @return Invisibly returns TRUE on success
syslog_warn <- function(message) {
  send_to_syslog("WARN", message)
}

#' Log an error message to syslog
#' 
#' @param message The message to log
#' @return Invisibly returns TRUE on success
syslog_error <- function(message) {
  send_to_syslog("ERROR", message)
}

#' Set the minimum log level for syslog
#' 
#' @param level New minimum log level (DEBUG, INFO, WARN, ERROR)
#' @return Invisibly returns the previous log level
set_syslog_level <- function(level) {
  level <- toupper(level)
  if (!level %in% names(SYSLOG_LOG_LEVELS)) {
    warning("Invalid log level specified. Not changing current level.")
    return(invisible(syslog_env$log_level))
  }
  
  previous <- syslog_env$log_level
  syslog_env$log_level <- level
  
  return(invisible(previous))
}

#' Change the syslog format
#' 
#' @param rfc5424 TRUE to use RFC5424 format, FALSE to use RFC3164 format
#' @return Invisibly returns the previous format setting
set_syslog_format <- function(rfc5424 = TRUE) {
  previous <- syslog_env$rfc5424
  syslog_env$rfc5424 <- rfc5424
  return(invisible(previous))
}

#' Check if syslog is enabled
#' 
#' @return TRUE if syslog is enabled, FALSE otherwise
is_syslog_enabled <- function() {
  return(syslog_env$enabled)
}