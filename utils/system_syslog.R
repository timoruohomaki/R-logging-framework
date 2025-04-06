# system_syslog.R - System Command-based Syslog Implementation

# Create environment to store syslog configuration
if (!exists("syslog_env", envir = .GlobalEnv)) {
  assign("syslog_env", new.env(), envir = .GlobalEnv)
  syslog_env$enabled <- FALSE
  syslog_env$host <- NULL
  syslog_env$port <- NULL
  syslog_env$facility <- 1  # user-level messages (default)
  syslog_env$hostname <- Sys.info()["nodename"]
  syslog_env$app_name <- "r-application"
  syslog_env$log_level <- "INFO"  # Default level
  syslog_env$rfc5424 <- TRUE
  
  # Set the system type explicitly
  syslog_env$system_type <- ifelse(.Platform$OS.type == "windows", "windows", "unix")
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

#' Initialize syslog settings
#' 
#' @param host Syslog server host
#' @param port Syslog server port
#' @param facility Syslog facility code (0-23)
#' @param app_name Application name to appear in syslog
#' @param level Minimum log level to record (DEBUG, INFO, WARN, ERROR)
#' @param rfc5424 Whether to use RFC5424 format (TRUE) or RFC3164 format (FALSE)
#' @return TRUE if initialized successfully
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
  
  # Store configuration
  syslog_env$host <- host
  syslog_env$port <- port
  syslog_env$enabled <- TRUE
  syslog_env$facility <- facility
  syslog_env$app_name <- app_name
  syslog_env$hostname <- Sys.info()["nodename"]
  syslog_env$rfc5424 <- rfc5424
  syslog_env$log_level <- level
  
  # Test if we can send a message
  test_result <- send_udp_message(host, port, 
                                  format_syslog_message("INFO", "Syslog initialized"))
  
  if (!test_result) {
    warning("Failed to send test message to syslog server")
    syslog_env$enabled <- FALSE
    return(FALSE)
  }
  
  return(TRUE)
}

#' Format a syslog message according to the chosen format
#' 
#' @param level Log level
#' @param message Message content
#' @return Formatted syslog message
format_syslog_message <- function(level, message) {
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
  
  return(syslog_msg)
}

#' Send a UDP message using system commands
#' 
#' @param host Destination host
#' @param port Destination port
#' @param message Message to send
#' @return TRUE if successful, FALSE otherwise
#' 

send_udp_message <- function(host, port, message) {
  # Create a temporary file with the message
  tmp_file <- tempfile()
  writeLines(message, tmp_file)
  
  success <- FALSE
  
  # Try Windows PowerShell first if on Windows
  if (.Platform$OS.type == "windows") {
    safe_message <- gsub("'", "''", message)
    ps_cmd <- sprintf(
      "$socket = New-Object System.Net.Sockets.UdpClient; $socket.Connect('%s', %d); $bytes = [System.Text.Encoding]::ASCII.GetBytes('%s'); $socket.Send($bytes, $bytes.Length) | Out-Null; $socket.Close()",
      host, port, safe_message
    )
    
    tryCatch({
      system(paste("powershell -Command", shQuote(ps_cmd)), intern = TRUE, ignore.stderr = TRUE)
      success <- TRUE
    }, error = function(e) {
      warning("PowerShell UDP method failed, trying alternatives")
    })
  }
  
  # If not successful yet, try Unix methods
  if (!success) {
    methods <- list(
      nc = sprintf("cat %s | nc -u %s %d 2>/dev/null", tmp_file, host, port),
      socat = sprintf("socat - UDP:%s:%d < %s 2>/dev/null", host, port, tmp_file),
      netcat = sprintf("cat %s | netcat -u %s %d 2>/dev/null", tmp_file, host, port)
    )
    
    for (name in names(methods)) {
      cmd <- methods[[name]]
      result <- tryCatch({
        system(cmd, ignore.stderr = TRUE)
      }, error = function(e) {
        warning(paste("Command failed:", name))
        return(1)
      })
      
      if (result == 0) {
        success <- TRUE
        break
      }
    }
  }
  
  # Clean up
  unlink(tmp_file)
  return(success)
}


#' Send a message to syslog
#' 
#' @param level Log level
#' @param message Message to log
#' @return TRUE if sent successfully, FALSE otherwise
send_to_syslog <- function(level, message) {
  if (!syslog_env$enabled || is.null(syslog_env$host) || is.null(syslog_env$port)) {
    return(FALSE)
  }
  
  level <- toupper(level)
  
  # Check if we should log this level
  if (SYSLOG_LOG_LEVELS[[level]] < SYSLOG_LOG_LEVELS[[syslog_env$log_level]]) {
    return(invisible(FALSE))
  }
  
  # Format the message
  syslog_msg <- format_syslog_message(level, message)
  
  # Send the message
  return(send_udp_message(syslog_env$host, syslog_env$port, syslog_msg))
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

#' Close syslog (disables syslog logging)
#' 
#' @return Always returns TRUE
close_syslog <- function() {
  syslog_env$enabled <- FALSE
  return(TRUE)
}