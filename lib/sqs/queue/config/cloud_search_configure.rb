module Sqs
  module Queue
    module Config
    end
  end
end

module Sqs::Queue::Config::CloudSearchConfigure
  QUEUE_NAME = "cs_import_search_item".freeze
  AWS_REGION = "us-west-2"
  AWS_ACCESS_KEY_ID = "AKIAIW4YAD7CAWY27ILQ"
  AWS_SECRET_ACCESS_KEY = "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"

  def poller_config
    {
      wait_time_seconds: 20,
      max_number_of_messages: 1,
      visibility_timeout: 1800,
      skip_delete: true
    }
  end


  def configure_aws!
    Aws.config.update(
      region: AWS_REGION,
      credentials: Aws::Credentials.new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
    )
  end

  def sqs_adapter
    @sqs_adapter ||= Sqs::Core::SqsAdapter.new(queue_name: QUEUE_NAME)
  end

  def queue_poller
    @queue_poller ||= sqs_adapter.queue_poller
  end

  def logger(logger_type = nil)
    current_date = Time.now.strftime("%Y%m%d")
    log_file_name = if logger_type.nil?
                      "#{QUEUE_NAME}_#{current_date}"
                    else
                      "#{logger_type}_#{QUEUE_NAME}_#{current_date}"
                    end
    log_file_location = "log/#{log_file_name}.log"
    logger = Logger.new(log_file_location)
    logger.level = Logger::DEBUG
    logger.datetime_format = "%Y-%m-%d %H:%M:%S"
    logger
  end

end

