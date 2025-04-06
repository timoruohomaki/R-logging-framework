# R Modular Logging System

A modular, flexible logging system for R applications with support for both file logging and syslog. This system allows for easy configuration, comprehensive logging options, and robust error handling.

## Features

- **Modular Design**: Separate modules for file logging and syslog
- **Flexible Configuration**: Configure each logging system independently
- **Multiple Log Levels**: DEBUG, INFO, WARN, ERROR with filtering
- **Syslog Support**: UDP-based syslog integration
- **Multiple Syslog Formats**: Support for both RFC5424 and RFC3164 formats
- **Robust Error Handling**: Graceful handling of file or network issues
- **Simple Unified Interface**: Single API for all logging needs

## Architecture

The logging system consists of three main modules:

1. **File Logger**: Handles logging to local files
2. **Syslog Logger**: Sends logs to a syslog server via UDP
3. **Combined Logger**: Integrates both systems with a unified interface

## Installation

1. Copy the logging modules to your project's `R/utils/` directory:
   - `file_logger.R`
   - `syslog_logger.R`
   - `logger.R`

2. Source the desired module in your R scripts:
   ```r
   source("R/utils/logger.R")  # For combined logging
   # OR
   source("R/utils/file_logger.R")  # For file logging only
   # OR
   source("R/utils/syslog_logger.R")  # For syslog only
   ```

## Usage Examples

### Combined Logging

```r
# Load the combined logger
source("R/utils/logger.R")

# Initialize both logging systems
initialize_logger(
  log_file = "application.log",
  syslog_host = "syslog-server.example.com",
  syslog_port = 514,
  level = "INFO",
  app_name = "my-application"
)

# Log messages to all enabled systems
log_info("Application started")
log_warn("Resource usage high: 85%")
log_error("Failed to connect to database")

# Close all connections when done
close_logger()
```

### File Logging Only

```r
# Load the file logger
source("R/utils/file_logger.R")

# Initialize file logging
initialize_file_logger(
  log_file = "application.log",
  append = TRUE,
  log_to_console = TRUE,
  level = "INFO"
)

# Log messages to file
log_info("Application started")
log_debug("This won't be logged if level is INFO")

# Change log level to see debug messages
set_log_level("DEBUG")
log_debug("Now this will be logged")

# Change log file
set_log_file("new_logfile.log", append = FALSE)
log_info("This goes to the new log file")
```

### Syslog Only

```r
# Load the syslog logger
source("R/utils/syslog_logger.R")

# Initialize syslog connection
initialize_syslog(
  host = "syslog-server.example.com",
  port = 514,
  facility = 1,  # user-level messages
  app_name = "my-application",
  level = "INFO",
  rfc5424 = TRUE  # Use modern format
)

# Log messages to syslog
syslog_info("Application started")
syslog_error("Database connection failed")

# Switch to legacy format
set_syslog_format(FALSE)
syslog_warn("Using legacy format now")

# Close connection when done
close_syslog()
```

## API Reference

### Combined Logger (logger.R)

#### Initialization

```r
initialize_logger(
  log_file = "application.log", 
  syslog_host = NULL,
  syslog_port = 514,
  level = "INFO",
  app_name = "r-application"
)
```

- `log_file`: Path to log file (NULL to disable file logging)
- `syslog_host`: Syslog server host (NULL to disable syslog)
- `syslog_port`: Syslog server port
- `level`: Minimum log level to record (DEBUG, INFO, WARN, ERROR)
- `app_name`: Application name for syslog

#### Logging Functions

```r
log_debug(message)  # Log a debug message
log_info(message)   # Log an informational message
log_warn(message)   # Log a warning message
log_error(message)  # Log an error message
```

#### Utility Functions

```r
close_logger()          # Close all logging connections
set_log_level(level)    # Set minimum log level for all loggers
```

### File Logger (file_logger.R)

#### Initialization

```r
initialize_file_logger(
  log_file = "application.log", 
  append = TRUE, 
  log_to_console = FALSE,
  level = "INFO"
)
```

- `log_file`: Path to the log file
- `append`: Whether to append to existing file or create new
- `log_to_console`: Also print log messages to console
- `level`: Minimum log level to record

#### Logging Functions

```r
log_debug(message)  # Log a debug message
log_info(message)   # Log an informational message
log_warn(message)   # Log a warning message
log_error(message)  # Log an error message
```

#### Utility Functions

```r
set_console_logging(enabled)  # Enable/disable console output
set_log_file(log_file, append)  # Change the log file
set_log_level(level)  # Set minimum log level
```

### Syslog Logger (syslog_logger.R)

#### Initialization

```r
initialize_syslog(
  host = "127.0.0.1", 
  port = 514, 
  facility = 1, 
  app_name = "r-application",
  level = "INFO",
  rfc5424 = TRUE
)
```

- `host`: Syslog server host
- `port`: Syslog server port
- `facility`: Syslog facility code (0-23)
- `app_name`: Application name
- `level`: Minimum log level
- `rfc5424`: Use modern format (TRUE) or legacy format (FALSE)

#### Logging Functions

```r
syslog_debug(message)  # Log a debug message
syslog_info(message)   # Log an informational message
syslog_warn(message)   # Log a warning message
syslog_error(message)  # Log an error message
```

#### Utility Functions

```r
close_syslog()  # Close syslog connection
set_syslog_level(level)  # Set minimum log level
set_syslog_format(rfc5424)  # Set format (TRUE=RFC5424, FALSE=RFC3164)
is_syslog_enabled()  # Check if syslog is enabled
```

## Log Format Examples

### File Log Format

```
[2023-07-15 14:23:45] [INFO] Application started
[2023-07-15 14:23:46] [WARN] Resource usage high: 85%
[2023-07-15 14:23:47] [ERROR] Failed to connect to database
```

### Syslog Format (RFC5424)

```
<134>1 2023-07-15T14:23:45+00:00 hostname my-application 12345 - Application started
<132>1 2023-07-15T14:23:46+00:00 hostname my-application 12345 - Resource usage high: 85%
<131>1 2023-07-15T14:23:47+00:00 hostname my-application 12345 - Failed to connect to database
```

### Syslog Format (RFC3164/BSD)

```
<134>Jul 15 14:23:45 hostname my-application[12345]: Application started
<132>Jul 15 14:23:46 hostname my-application[12345]: Resource usage high: 85%
<131>Jul 15 14:23:47 hostname my-application[12345]: Failed to connect to database
```

## Syslog Facility Codes

| Code | Facility |
|------|----------|
| 0 | kernel messages |
| 1 | user-level messages |
| 2 | mail system |
| 3 | system daemons |
| 4 | security/authorization messages |
| 5 | messages generated internally by syslogd |
| 6 | line printer subsystem |
| 7 | network news subsystem |
| 8 | UUCP subsystem |
| 9 | clock daemon |
| 10 | security/authorization messages |
| 11 | FTP daemon |
| 12 | NTP subsystem |
| 13 | log audit |
| 14 | log alert |
| 15 | clock daemon |
| 16-23 | local use 0-7 (local0-local7) |

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

4. **Close Connections**:
   - Always call `close_logger()` when your application exits

5. **Use Structured Logging When Possible**:
   - Consider using JSON format for complex log data
   - Enable easy parsing and analysis

## Troubleshooting

### File Logging Issues

- Ensure the destination directory exists and is writable
- Check for file permissions issues
- Verify disk space availability

### Syslog Issues

- Ensure the syslog server is running and accepting UDP connections
- Check firewall settings that might block UDP port 514
- Verify network connectivity between your application and syslog server

## License

This code is distributed under the MIT License.