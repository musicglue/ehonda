class ProcessedMessage < ActiveRecord::Base
  self.primary_key = 'sqs_id'

  validates :message_id, presence: true
  validates :queue, presence: true
  validates :message, presence: true
end
