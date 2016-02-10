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
    history = SlackClient.new.groups_history(channel: STANDUP_CHANNEL, oldest: to_timestamp(DateTime.now - 10.minutes))
    messages = history['messages']
    users_who_wrote = messages.map{ |msg| msg['user'] }
    users_who_wrote
  end

  def buzz_all!(didnt_wrote)
    didnt_wrote.uniq.each do |user_id|
      buzz!(user_id)
    end

    notify_about_all_who_didnt_wrote(didnt_wrote)
  end

  def buzz!(user_id)
    user_info = SlackClient.new.users_info(user: user_id)
    SlackClient.new.chat_postMessage(
      channel: STANDUP_CHANNEL,
      text: "Hey, #{user_info['user']['name']}! Ty jsi za včerejšek nenapsal standup!",
      username: 'Standup checker',
      icon_url: ENV['STANDUP_BOT_ICON_URL']
    )
  end

  def notify_about_all_who_didnt_wrote(didnt_wrote)
    users_names = SlackClient.new.users_list['members'].select{ |u| didnt_wrote.include?(u['id']) }.map{ |u| u['name'] }
    names = ''
    users_names.each_with_index do |name, i|
      names += ', ' if i != 0
      names += name
    end
    SlackClient.new.chat_postMessage(
      channel: STANDUP_CHANNEL,
      text: "Za včerejšek nenapsali standup tito lidé: #{names}",
      username: 'Standup checker',
      icon_url: ENV['STANDUP_BOT_ICON_URL']
    )
  end

  def to_timestamp(ago)
    ago.strftime('%s')
  end

  end
end