class GithubChecker

  def self.check_commits_count_for_yesterday!

    all_commits = GithubClient.new.commits_since(ENV['GITHUB_STATS_REPO'], DateTime.now-1.day, per_page: 500)

    names_with_commits_count = {}
    all_commits.group_by{
      |c| c[:author][:login]
    }.map{
      |commiter, commits| names_with_commits_count[commiter.to_s] = commits.size
    }

    sorted_hash = Hash[ names_with_commits_count.sort_by{ |k,v| v }.reverse ]

    message = "*Statistika commitů za posledních 24 hodin:*\n\n"
    sorted_hash.each{ |k,v| message += "#{k}: #{v}\n" }

    who_didnt_wrote = about_who_notify.select{ |c| !names_with_commits_count.has_key?(c) }

    if who_didnt_wrote.any?
      message += "\n\n*Necommitnuli:* \n"
      who_didnt_wrote.each{ |didnt| message += "#{didnt}\n" }
    end

    Rails.logger.info("Notified message: #{message}")

    whom_yesterday_stats.each do |whom|
      SlackClient.new.chat_postMessage(
        channel: whom,
        text: message,
        username: 'Github snitch',
        icon_url: ENV['GITHUB_BOT_ICON_URL']
      )
    end
  end

  def self.about_who_notify
    about_who = ENV.select{ |var| var.include?('GITHUB_STATS_USER') }.map{|k,v| v}
    Rails.logger.info("Get Github stats about: #{about_who}")
    about_who
  end

  def self.whom_yesterday_stats
    whom_notify = ENV.select{ |var| var.include?('GITHUB_STATS_NOTIFY') }.map{|k,v| v}
    Rails.logger.info("Notified about Github commits stats: #{whom_notify}")
    whom_notify
  end

end