class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :slack_id, null: false
      t.integer :standup_counter, default: 0
      t.references :standup, index: true, foreign_key: true
      t.boolean :standup_notifications, default: false

      t.timestamps null: false
    end
    add_index :users, :slack_id, unique: true
  end
end
