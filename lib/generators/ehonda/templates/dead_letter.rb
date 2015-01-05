class DeadLetter < ActiveRecord::Base
  self.primary_key = 'sqs_id'

  validates :sqs_id, presence: true
  validates :message_id, presence: true
  validates :message, presence: true

  def self.retryable sqs_id: nil, message_id: nil
    criteria = all
    criteria = criteria.where(sqs_id: sqs_id) unless sqs_id.blank?
    criteria = criteria.where(message_id: message_id) unless message_id.blank?
    criteria
  end
end
