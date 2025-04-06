# R Logging Framework

Logging framework for R that supports local log files and sending events to syslog.

> [!NOTE]
> This project is an experimentation of pair-programming with Claude.ai using Claude 3.7 Sonnet -model.
> The project was created by incremental addition of functionality and finally documentation.

## Notes on the Implementation:

* UDP Connection: This uses UDP which is the traditional transport for syslog. It's connectionless and doesn't guarantee delivery.
* RFC5424 Format: The implementation follows the modern syslog protocol format (RFC5424).
* Error Handling: There's robust error handling to prevent syslog failures from affecting your application.
* Configuration: You can configure the syslog host, port, facility, and application name.
* Level Mapping: The function maps your log levels to standard syslog severity levels.

If you need to support both older BSD syslog format (RFC3164) and newer RFC5424 format, you might want to add a parameter to switch between them based on your syslog server's capabilities.

A comprehensive documentation of the project is maintained at [OVERVIEW.md](OVERVIEW.md)


