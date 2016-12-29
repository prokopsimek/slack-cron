class CreateStandups < ActiveRecord::Migration
  def change
    create_table :standups do |t|
      t.string :name
      t.string :slack_api_token
      t.string :channel_read_from
      t.string :cron
      t.boolean :is_active
      t.string :bot_icon_url
      t.string :bot_icon_happy_url
      t.string :message_all_wrote
      t.string :message_to_notified
      t.string :message_to_user
      t.string :message_to_user_count_not_written

      t.timestamps null: false
    end
  end
end
