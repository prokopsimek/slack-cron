class StandupChecker

  STANDUP_CHANNEL = ENV['STANDUP_CHANNEL']

  class << self

    def get_who_should_write
      who_should_write = ENV.select{ |var| var.include?('STANDUP_USER') }.map{|k,v| v}
      Rails.logger.info("Should write: #{who_should_write.inspect}")
      who_should_write
    end

    def get_whom_to_nofity_result
      whom_to_nofity = ENV.select{ |var| var.include?('STANDUP_NOTIFY') }.map{|k,v| v}
      Rails.logger.info("Whom to notify: #{whom_to_nofity.inspect}")
      whom_to_nofity
    end

  def process!
    should_write = get_who_should_write

    who_wrotes = get_who_wrote
    Rails.logger.info("Who wrotes: #{who_wrotes.inspect}")

    didnt_wrote = should_write - who_wrotes
    Rails.logger.info("Who didn't wrote: #{didnt_wrote.inspect}")

    buzz_all!(didnt_wrote)
  end

  def get_who_wrote
    history = SlackClient.new.channels_history(channel: STANDUP_CHANNEL, oldest: to_timestamp(DateTime.now - 21.hours)) # day before at 9pm
    raise StandardError.new("Something went wrong! #{history.inspect}") if history['ok'].to_s == 'false'
    messages = history['messages']
    Rails.logger.info("Slack messages: #{messages.inspect}")

    if messages.present?
      users_who_wrote = messages.map{ |msg| msg['user'] }.uniq
    else
      users_who_wrote = []
    end

    users_who_wrote
  end

  def buzz_all!(didnt_wrote)
    didnt_wrote.uniq.each do |user_id|
      buzz!(user_id)
    end

    get_whom_to_nofity_result.each do |whom_id|
      if didnt_wrote.any?
        notify_about_all_who_didnt_wrote(didnt_wrote, whom_id)
      else
        notify_that_all_wrote(whom_id)
      end
    end
  end

  def buzz!(user_id)
    SlackClient.new.chat_postMessage(
      channel: user_id,
      text: "Hey, <@#{user_id}>! Ty jsi za včerejšek nenapsal standup!",
      username: 'Standup checker',
      icon_url: ENV['STANDUP_BOT_ICON_URL']
    )
    Rails.logger.info("Buzzed user: #{user_id}")
  end

  def notify_about_all_who_didnt_wrote(didnt_wrote, whom_id)
    names = ''
    didnt_wrote.each_with_index do |user_id, i|
      names += ', ' if i != 0
      names += "<@#{user_id}>"
    end

    Rails.logger.info("Notified about buzzed users: #{whom_id}")

    SlackClient.new.chat_postMessage(
      channel: whom_id,
      text: "Za včerejšek nenapsali standup tito lidé: #{names}!",
      username: 'Standup bitch',
      icon_url: ENV['STANDUP_BOT_ICON_URL']
    )
  end

  def notify_that_all_wrote(whom_id)
    Rails.logger.info("Notified about all wrote: #{whom_id}")
    SlackClient.new.chat_postMessage(
      channel: whom_id,
      text: "Za včerejšek napsali standup všichni lidé, od kterých to je vyžadováno.",
      username: 'Standup checker',
      icon_url: ENV['STANDUP_BOT_ICON_URL']
    )
  end

  def to_timestamp(ago)
    timestamp = ago.to_i
    Rails.logger.info("Got timestamp: #{timestamp}")
    timestamp
  end

  end
end