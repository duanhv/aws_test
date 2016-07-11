# endcoding: utf-8
# fzen_string_literal: true
require "aws-sdk"
require "yaml"
require "logger"
require "./lib/sqs/core/sqs_adapter.rb"
require "./lib/sqs/queue/config/cloud_search_configure.rb"

module Sqs
  module Queue
    module Pollers
    end
  end
end

class Sqs::Queue::Pollers::CloudSearchImportation
  extend Sqs::Queue::Config::CloudSearchConfigure
  class << self
    def execute!

      logger.info("start execution")
      configure_aws!    	

      queue_poller.poll(poller_config) do |message, stats|
        
	logger.info(message.body)
        throw :stop_polling
      end

      logger.info("finish execution...")
    
    rescue => e
      logger.error(e)
    end
  end
end
