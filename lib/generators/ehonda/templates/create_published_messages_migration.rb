class EhondaCreatePublishedMessages < ActiveRecord::Migration
  def change
    create_table :published_messages, id: :uuid do |t|
      t.timestamps null: false

      t.string :topic, null: false
      t.json :message, null: false
      t.json :response

      t.integer :attempts, null: false, default: 0
      t.datetime :attempted_at

      t.string :published_by
      t.datetime :published_at

      t.index :published_by
      t.index :published_at
    end
  end
end
