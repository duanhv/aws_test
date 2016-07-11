module Sqs
  module Core
  end
end

class Sqs::Core::SqsAdapter
  def initialize(sqs_client: Aws::SQS::Client.new, queue_name:, retry_limit: 3)
    @sqs_client = sqs_client
    @retry_limit = retry_limit
    begin
      @queue_url = sqs_client.get_queue_url(queue_name: queue_name).queue_url
      puts @queue_url
    rescue Aws::SQS::Errors::NonExistentQueue
      p "This queue does not exist for this wsdl version."
    end
  end

  def send_message(message)
    @sqs_client.send_message(
      queue_url: @queue_url,
      message_body: message
    )
  end

  def send_message_batch(messages)
    messages_queue = messages.each_slice(10).to_a
    retries = 0

    begin
      until messages_queue.empty?
        message_subset = messages_queue.pop
        send_messages_by_subsets!(message_subset, messages_queue)
      end

    rescue Aws::SQS::Errors::ServiceError => e
      retries = raise_or_sleep_with_incremental_retries(e, retries)
      messages_queue.push(message_subset)
      retry
    end
  end

  def receive_message(options = {})
    @sqs_client.receive_message(
      queue_url: @queue_url,
      max_number_of_messages: options[:max_number_of_messages],
      visibility_timeout: options[:visibility_timeout],
      wait_time_seconds: options[:wait_time_seconds]
    )
  end

  def queue_poller
    @queue_poller ||= Aws::SQS::QueuePoller.new(@queue_url)
  end

  def appr_number_of_messages
    @sqs_client.get_queue_attributes(
      queue_url: @queue_url,
      attribute_names: ["ApproximateNumberOfMessages"]
    ).attributes.values.first.to_i
  end

  def appr_number_of_messages_not_visb
    @sqs_client.get_queue_attributes(
      queue_url: @queue_url,
      attribute_names: ["ApproximateNumberOfMessagesNotVisible"]
    ).attributes.values.first.to_i
  end

  def purge_queue!
    @sqs_client.purge_queue(queue_url: @queue_url)
  end

  private

  def send_messages_by_subsets!(message_subset, messages_queue)
    response = @sqs_client.send_message_batch(
      queue_url: @queue_url,
      entries: message_subset
    )

    return unless response.failed.any?

    successful_ids = response.successful.map(&:id)
    message_subset.reject! { |message| successful_ids.inclucde?(message[:id]) }
    messages_queue.push(message_subset)
  end

  def raise_or_sleep_with_incremental_retries(e, retries)
    raise e if retries >= @retry_limit
    sleep(3**retries)
    retries + 1
  end
end
