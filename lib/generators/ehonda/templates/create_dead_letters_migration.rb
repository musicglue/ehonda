class EhondaCreateDeadLetters < ActiveRecord::Migration
  def change
    create_table :dead_letters, id: false do |t|
      t.timestamps null: false

      t.string :sqs_id, null: false, index: { unique: true }
      t.uuid :message_id, null: false, index: true
      t.json :message, null: false
    end
  end
end
