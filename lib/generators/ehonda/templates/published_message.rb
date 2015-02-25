class PublishedMessage < ActiveRecord::Base
  def self.unsent
    where(published_at: nil)
      .where('attempted_at IS NULL OR (attempted_at <= ?)', 1.minute.ago)
      .order(created_at: :asc)
  end

  def self.sent_by publisher_id, timestamp
    where(published_by: publisher_id, attempted_at: timestamp)
  end

  validates :message, presence: true
  validates :topic, presence: true

  def self.publish message, header = {}
    topic_name = message.class.to_s.underscore.dasherize.sub(/-message$/, '')
    publish_raw(topic_name, header, message.attributes)
  end

  def self.publish_raw topic_name, body, header = {}
    header.merge!(type: topic_name).reverse_merge!(id: SecureRandom.uuid, version: 1)

    PublishedMessage.create!(
      topic: topic_name,
      message: {
        header: header,
        body: body
      })
  end
end
