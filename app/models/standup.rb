class Standup < ActiveRecord::Base

  validates :name, :slack_api_token, :channel_read_from, :cron, :message_to_user, presence: true

  has_many :users

end
