# R File Logger

A simple, reliable file-based logging system for R applications. This logger provides a clean interface for logging messages at different severity levels with flexible configuration options.

## Features

- **Multiple Log Levels**: DEBUG, INFO, WARN, ERROR with level filtering
- **Flexible Configuration**: Configurable log file path, append mode, and console output
- **Timestamp Formatting**: Automatic timestamping of all log entries
- **Directory Creation**: Automatically creates log directories if they don't exist
- **Console Mirroring**: Option to display log messages in the console in addition to writing to file
- **Robust Error Handling**: Graceful handling of file system issues

## Installation

Copy the `logger.R` file to your project's `R/utils/` directory:

```bash
# Create directory if it doesn't exist
mkdir -p R/utils/

# Copy the logger file
cp path/to/logger.R R/utils/
```

## Basic Usage

```r
# Load the logger
source("R/utils/logger.R")

# Initialize with default settings (logs to "logs/application.log")
initialize_logger()

# Or specify a custom log location
initialize_logger(
  log_dir = "path/to/logs",
  log_file = "myapp.log"
)

# Log messages at different levels
log_info("Application started")
log_debug("Detailed debugging information")
log_warn("Warning condition detected")
log_error("Error occurred while processing data")

# Close the logger when done
close_logger()
```

## Configuration Options

### Initialize with Custom Settings

```r
initialize_logger(
  log_file = "logs/my_application.log",  # Custom log file path
  append = TRUE,                         # Append to existing log (FALSE to overwrite)
  log_to_console = TRUE,                 # Also show logs in console
  level = "DEBUG"                        # Set minimum log level
)
```

### Change Settings During Runtime

```r
# Change log level
set_log_level("DEBUG")  # Show all messages including debug
set_log_level("WARN")   # Only show warnings and errors

# Change log file (keeps same directory)
set_log_file("new_logfile.log")
set_log_file("archive.log", append = FALSE)  # Create new file, don't append

# Change log directory (keeps same filename)
set_log_dir("logs/errors")  # Will now log to logs/errors/current_filename.log

# Set complete log path (both directory and filename)
set_log_path("logs/archive/2023/app.log")

# Toggle console output
set_console_logging(TRUE)   # Show logs in console
set_console_logging(FALSE)  # Don't show logs in console
```

## Log Levels

The logger supports four standard log levels:

1. **DEBUG**: Detailed information, typically useful only when diagnosing problems
2. **INFO**: Confirmation that things are working as expected
3. **WARN**: Indication that something unexpected happened, or may happen in the near future
4. **ERROR**: A serious problem that needs to be addressed

Messages are only logged if their level is greater than or equal to the current logger level.

## Log Format

Log entries are formatted as:

```
[YYYY-MM-DD HH:MM:SS] [LEVEL] Message
```

Example:
```
[2023-07-15 14:23:45] [INFO] Application started
[2023-07-15 14:23:46] [WARN] Resource usage high: 85%
[2023-07-15 14:23:47] [ERROR] Failed to connect to database
```

## Example: Creating Timestamped Log Files

```r
# Create daily log directories with timestamped files
daily_dir <- paste0("logs/", format(Sys.Date(), "%Y%m%d"))
set_log_dir(daily_dir)
set_log_file(paste0("app_", format(Sys.time(), "%H%M%S"), ".log"))
log_info(paste("Logging to timestamped file:", get_log_path()))

# Or use set_log_path for a complete path
timestamped_log <- paste0("logs/daily/", format(Sys.Date(), "%Y%m%d"), 
                         "/app_", format(Sys.time(), "%H%M%S"), ".log")
set_log_path(timestamped_log)
log_info(paste("Logging to:", get_log_path()))
```

## Example: Using in Functions

```r
process_data <- function(file_path) {
  log_info(paste("Starting to process", file_path))
  
  tryCatch({
    # Simulation of processing
    log_debug("Reading file contents")
    # ... actual processing code here ...
    
    log_info(paste("Successfully processed", file_path))
    return(TRUE)
  }, error = function(e) {
    log_error(paste("Error processing", file_path, ":", e$message))
    return(FALSE)
  })
}
```

## Best Practices

1. **Choose the Right Log Level**:
   - DEBUG: Detailed information for troubleshooting
   - INFO: General information about application progress
   - WARN: Potential issues that don't prevent operation
   - ERROR: Problems that prevent normal operation

2. **Include Contextual Information**:
   - Add relevant details to log messages
   - Consider including user IDs, request IDs, or session information

3. **Be Mindful of Sensitive Data**:
   - Don't log passwords, API keys, or personal information
   - Be careful with data that might be subject to privacy regulations

4. **Close the Logger**:
   - Always call `close_logger()` when your application exits

5. **Organize Logs**:
   - Consider using separate log files for different components
   - Use timestamped log file names for easier archiving

## API Reference

### Initialization

```r
initialize_logger(
  log_dir = "logs",
  log_file = "application.log", 
  append = TRUE, 
  log_to_console = FALSE,
  level = "INFO"
)
```

- `log_dir`: Directory for log files
- `log_file`: Name of the log file (relative to log_dir)
- `append`: Whether to append to existing file or create new
- `log_to_console`: Also print log messages to console
- `level`: Minimum log level to record

### Logging Functions

```r
log_debug(message)  # Log a debug message
log_info(message)   # Log an informational message
log_warn(message)   # Log a warning message
log_error(message)  # Log an error message
```

### Utility Functions

```r
set_console_logging(enabled)         # Enable/disable console output
set_log_file(log_file, append)       # Change the log file (keeps same directory)
set_log_dir(log_dir)                 # Change the log directory
set_log_path(log_path, append)       # Set complete log path (dir and file)
set_log_level(level)                 # Set minimum log level
get_log_path()                       # Get the full path to the current log file
close_logger()                       # Close the logger
flush_logger()                       # Flush any buffered log messages
```

## Extending the Logger

The file logger can be extended in several ways:

1. **Rotation**: Add log rotation functionality to manage file sizes
2. **Formatting**: Customize the log message format
3. **Syslog**: Add functionality to send logs to syslog (on supported platforms)
4. **Async Logging**: Implement asynchronous logging for better performance

## Troubleshooting

### Common Issues

1. **Cannot write to log file**:
   - Check if the directory exists
   - Verify file permissions
   - Ensure sufficient disk space

2. **Missing log messages**:
   - Check if the log level is set correctly
   - Verify the log file path

3. **Performance issues**:
   - Consider using a more efficient logging strategy for high-volume logs
   - Avoid excessive debug logging in production environments

## License

This code is distributed under the MIT License.