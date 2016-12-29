class StandupJob
  include Sidekiq::Worker
  def perform
    Standup.where(is_active: true).each do |standup|
      Checker::Standup.run_standup(standup)
    end
  end
end
