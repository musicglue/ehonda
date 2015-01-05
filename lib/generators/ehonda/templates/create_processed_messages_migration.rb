class EhondaCreateProcessedMessages < ActiveRecord::Migration
  def change
    create_table :processed_messages, id: false do |t|
      t.timestamps null: false

      t.string :sqs_id, null: false, index: { unique: true }
      t.uuid :message_id, null: false
      t.string :queue, null: false
      t.json :message, null: false

      t.index %i(message_id queue), unique: true
    end
  end
end
