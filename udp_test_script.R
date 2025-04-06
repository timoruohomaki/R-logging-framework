send_syslog_system_command <- function(host, port, message, facility = 1, severity = 6) {
  # Calculate priority value
  priority <- facility * 8 + severity
  
  # Format the message
  formatted_message <- sprintf("<%d>%s", priority, message)
  
  # Use system command based on platform
  if (.Platform$OS.type == "windows") {
    # For Windows, use PowerShell (if available)
    ps_cmd <- sprintf(
      "$socket = New-Object System.Net.Sockets.UdpClient; $socket.Connect('%s', %d); $bytes = [System.Text.Encoding]::ASCII.GetBytes('%s'); $socket.Send($bytes, $bytes.Length); $socket.Close()",
      host, port, formatted_message
    )
    system(paste("powershell -Command", shQuote(ps_cmd)), intern = TRUE)
    return(TRUE)
  } else {
    # For Unix-like systems, try netcat or socat
    if (system("which nc > /dev/null") == 0) {
      # Netcat is available
      tmp_file <- tempfile()
      writeLines(formatted_message, tmp_file)
      cmd <- sprintf("cat %s | nc -u -w 1 %s %d", tmp_file, host, port)
      result <- system(cmd)
      unlink(tmp_file)
      return(result == 0)
    } else if (system("which socat > /dev/null") == 0) {
      # Try socat if netcat isn't available
      cmd <- sprintf("echo '%s' | socat - UDP:%s:%d", 
                     formatted_message, host, port)
      result <- system(cmd)
      return(result == 0)
    } else {
      warning("Neither netcat nor socat available")
      return(FALSE)
    }
  }
}

# Test using system command
send_syslog_system_command("10.0.2.58", 514, "Test message via system command")