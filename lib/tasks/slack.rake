namespace :slack do
  task notify: :environment do
    if Date.today.wday != 0 && Date.today.wday != 1
      Standup.where(is_active: true).each do |standup|
        Checker::Standup.run_standup(standup)
      end
    end
  end
end
