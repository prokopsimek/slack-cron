namespace :slack do
  task notify: :environment do
    # if Date.today.wday != 0 && Date.today.wday != 1
    #   StandupChecker.process!
    # end
  end
end
