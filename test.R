source("utils/python_syslog.R")

# Initialize with the path to your Python executable if needed
initialize_syslog(
  host = "10.0.2.58",
  port = 514,
  app_name = "r-test-app",
  python_path = "python"  # or "python3" or full path if needed
)

syslog_info("Test message via Python")
syslog_warn("Warning message")
syslog_error("Error message")

close_syslog()