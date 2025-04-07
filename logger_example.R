# logger_example.R - Usage Example
#
# This script demonstrates how to use the file-based logging module

# Load the logger module
source("utils/logger.R")

# Basic initialization with log directory
initialize_logger(
  log_dir = "logs",
  log_file = "application.log",
  append = TRUE,
  log_to_console = TRUE,
  level = "INFO"
)

# Log messages at different levels
log_info("Application started")
log_debug("This debug message will not appear if level is INFO")
log_warn("Warning: disk space is running low")
log_error("Error: could not connect to database")

# Change log level to see debug messages
set_log_level("DEBUG")
log_debug("Now this debug message will appear")

# Log to a different file (in the same directory)
set_log_file("detailed_log.log", append = FALSE)
log_info("This message goes to the new log file")

# Change the log directory
set_log_dir("logs/debug")
set_log_file("debug.log")
log_info("This message goes to logs/debug/debug.log")

# Set a complete log path (changes both directory and file)
set_log_path("logs/archive/archive.log")
log_info("This message goes to logs/archive/archive.log")

# Turn off console output
set_console_logging(FALSE)
log_info("This message only goes to the log file, not the console")

# Turn console output back on
set_console_logging(TRUE)
log_info("This message goes to both the log file and the console")

# Create a timestamped log file (using set_log_path)
timestamped_log <- paste0("logs/daily/", format(Sys.Date(), "%Y%m%d"), "/app_", 
                          format(Sys.time(), "%H%M%S"), ".log")
set_log_path(timestamped_log)
log_info(paste("Logging to timestamped file:", timestamped_log))

# Log some sample application events
log_info("User logged in: user123")
log_debug("Session ID: ABC123XYZ")
log_info("Processing file: data.csv")
log_debug("File size: 1.2 MB, 500 records")
log_warn("Some records have missing values")
log_info("Processing completed")
log_info("User logged out: user123")

# Close the logger when done
close_logger()

# Example of using the logger in a function
process_data <- function(file_path) {
  log_info(paste("Starting to process", file_path))
  
  tryCatch({
    # Simulate some processing
    log_debug("Reading file contents")
    Sys.sleep(1)
    
    log_debug("Performing calculations")
    result <- runif(5)
    log_debug(paste("Result:", paste(round(result, 2), collapse = ", ")))
    
    log_info(paste("Successfully processed", file_path))
    return(result)
  }, error = function(e) {
    log_error(paste("Error processing", file_path, ":", e$message))
    return(NULL)
  })
}

# Try the function
process_data("sample.txt")