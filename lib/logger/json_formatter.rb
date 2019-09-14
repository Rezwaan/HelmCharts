class Logger
  class JsonFormatter < Logger::Formatter
    def call(severity, time, progname, msg)
      {
        time: format_datetime(time),
        severity: severity,
        message: msg2str(msg),
        pid: $$,
        progname: progname,
      }
    end
  end
end
