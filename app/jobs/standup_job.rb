class StandupJob
  include Sidekiq::Worker
  def perform
    # StandupChecker.process!
  end
end
