class StandupChecker

  STANDUP_CHANNEL = ENV['STANDUP_CHANNEL']

  class << self

  def process!
    should_write = ENV.select{ |var| var.include?('STANDUP_USER') }.map{|k,v| v}

    who_wrotes = get_who_wrote
    didnt_wrote = should_write - who_wrotes

    buzz_all!(didnt_wrote)
  end

  def get_who_wrote
    history = SlackClient.new.groups_history(channel: STANDUP_CHANNEL, oldest: to_timestamp(DateTime.now - 1.minutes))
    messages = history['messages']
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

    if didnt_wrote.any?
      notify_about_all_who_didnt_wrote(didnt_wrote)
    else
      notify_that_all_wrote
    end
  end

  def buzz!(user_id)
    SlackClient.new.chat_postMessage(
      channel: STANDUP_CHANNEL,
      text: "Hey, <@#{user_id}>! Ty jsi za včerejšek nenapsal standup!",
      username: 'Standup checker',
      icon_url: ENV['STANDUP_BOT_ICON_URL']
    )
  end

  def notify_about_all_who_didnt_wrote(didnt_wrote)
    names = ''
    didnt_wrote.each_with_index do |user_id, i|
      names += ', ' if i != 0
      names += "<@#{user_id}>"
    end
    SlackClient.new.chat_postMessage(
      channel: STANDUP_CHANNEL,
      text: "Za včerejšek nenapsali standup tito lidé: #{names}!",
      username: 'Standup checker',
      icon_url: ENV['STANDUP_BOT_ICON_URL']
    )
  end

  def notify_that_all_wrote
    SlackClient.new.chat_postMessage(
      channel: STANDUP_CHANNEL,
      text: "Za včerejšek napsali standup všichni lidé, od kterých to je vyžadováno.",
      username: 'Standup checker',
      icon_url: ENV['STANDUP_BOT_ICON_URL']
    )
  end

  def to_timestamp(ago)
    ago.strftime('%s')
  end

  end
end