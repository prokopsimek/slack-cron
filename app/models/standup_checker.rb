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
    history = SlackClient.new.groups_history(channel: STANDUP_CHANNEL, oldest: to_timestamp(DateTime.now - 5.minutes))
    messages = history['messages']
    users_who_wrote = messages.map{ |msg| msg['user'] }
    users_who_wrote
  end

  def buzz_all!(didnt_wrote)
    didnt_wrote.uniq.each do |user_id|
      buzz!(user_id)
    end
  end

  def buzz!(user_id)
    SlackClient.new.chat_postMessage(
      channel: user_id,
      text: "Hey, <@#{user_id}>! Ty jsi za včerejšek nenapsal standup!",
      username: 'Standup checker',
      icon_url: ENV['STANDUP_BOT_ICON_URL']
    )
  end

  def to_timestamp(ago)
    ago.strftime('%s')
  end

  end
end