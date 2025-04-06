source("utils/system_syslog.R")

initialize_syslog(
  host = "10.0.2.58",
  port = 514,
  app_name = "r-test-app"
)

syslog_info("Test message via system commands")
syslog_warn("Warning message")
syslog_error("Error message")

close_syslog()