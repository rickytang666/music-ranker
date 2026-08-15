# cloud run parses json stdout into filterable fields, dev keeps the plain format
return unless Rails.env.production?

class JsonLogFormatter < ActiveSupport::Logger::SimpleFormatter
  include ActiveSupport::TaggedLogging::Formatter

  # ruby logger severities on the left, cloud logging severities on the right
  SEVERITY = {
    "DEBUG" => "DEBUG",
    "INFO"  => "INFO",
    "WARN"  => "WARNING",
    "ERROR" => "ERROR",
    "FATAL" => "CRITICAL"
  }.freeze

  def call(severity, time, _progname, msg)
    payload = {
      severity: SEVERITY.fetch(severity, "DEFAULT"),
      time: time.utc.iso8601(3),
      message: normalize(msg)
    }
    # config.log_tags puts request_id first, promote it to its own field
    payload[:request_id] = current_tags.first if current_tags.any?

    "#{payload.to_json}\n"
  end

  private

  def normalize(msg)
    case msg
    when String    then msg
    when Exception then "#{msg.class}: #{msg.message}"
    else msg.inspect
    end
  end
end

Rails.logger.formatter = JsonLogFormatter.new
