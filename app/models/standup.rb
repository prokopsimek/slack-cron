class Standup < ActiveRecord::Base

  after_commit :reload_schedule

  validates :name, :slack_api_token, :channel_read_from, :cron, :message_to_user, presence: true

  has_many :users

  private
  
  def reload_schedule
    Sidekiq::Scheduler.reload_schedule!
  end

end
