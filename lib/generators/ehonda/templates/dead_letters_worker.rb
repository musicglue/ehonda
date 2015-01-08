class DeadLettersWorker
  include Shoryuken::Worker

  shoryuken_options(
    auto_delete: true,
    body_parser: :json,
    subscriptions: { your_dead_letter_queue: '*' })

  def perform sqs_message, payload
    typed_message = Ehonda::TypedMessage.new sqs_message

    return if DeadLetter.exists? message_id: typed_message.id

    DeadLetter.create!(
      sqs_id: sqs_message.message_id,
      message_id: typed_message.id,
      message: typed_message.to_h)
  end
end
