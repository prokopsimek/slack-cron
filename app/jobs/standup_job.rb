class StandupJob
  include Sidekiq::Worker
  def perform
    # check if all have written standup today
  end
end