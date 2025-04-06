# logger_example.R - Usage Example
#
# This script demonstrates how to use the split logging modules

# Testing connectivity

# Check available network interfaces
if (.Platform$OS.type == "windows") {
  system("ipconfig /all")
} else {
  system("ifconfig -a || ip addr")
}

# Load the modules directly for specific logging needs
# Option 1: Use only file logging

source("utils/file_logger.R")

# create local log data folder 

if(!file.exists("./log")){dir.create("./log")}

# Initialize file logging only
initialize_file_logger(
  log_file = "log/application.log",
  append = TRUE,
  log_to_console = TRUE,
  level = "INFO"
)

log_info("This message only goes to the file log")
log_debug("This debug message will not appear if level is INFO")

# Set a different log level to see debug messages
set_log_level("DEBUG")
log_debug("Now this debug message will appear")

# Change the log file
set_log_file("log/another_log.log", append = FALSE)
log_info("This message goes to the new log file")

# Option 2: Use only syslog logging
source("utils/syslog_logger_simplified.R")

# Initialize syslog only
initialize_syslog(
  host = "10.0.2.58",  # Local syslog server
  port = 514,
  facility = 1,        # User-level messages
  app_name = "r-app-to-syslog-test",
  level = "INFO",
  rfc5424 = TRUE       # Use modern format
)

syslog_info("This message only goes to syslog")
syslog_error("This is an error message for syslog")

# Change syslog format to older BSD style
set_syslog_format(FALSE)
syslog_warn("This warning uses the older RFC3164 format")

# Close the syslog connection when done
close_syslog()

# Option 3: Use the combined logger for both
source("utils/logger.R")  # This loads both modules

# Initialize both logging systems
initialize_logger(
  log_file = "log/combined.log",
  syslog_host = "10.0.2.58",
  syslog_port = 514,
  level = "INFO",
  app_name = "combined-logger-example"
)

# These messages go to both the file and syslog
log_info("This message goes to both loggers")
log_warn("This warning appears in both systems")
log_error("This error is logged everywhere")

# Close all connections when done
close_logger()

# Advanced usage: Selectively enable/disable logging systems
initialize_logger(
  log_file = "log/selective.log",  # Enable file logging
  syslog_host = NULL           # Disable syslog
)

log_info("This message only goes to the file log")

# Later enable syslog too
initialize_syslog(
  host = "10.0.2.58",
  port = 514,
  app_name = "dynamic-logger"
)

log_info("Now this message goes to both systems")

# Close everything when done
close_logger()