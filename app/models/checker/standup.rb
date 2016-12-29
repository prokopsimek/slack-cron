class Checker::Standup

  class << self

    def run_standup(standup)
      @standup = standup

      if @standup.is_active?
        process!
      else
        Rails.logger.info("Standup #{@standup.id} disabled")
        false
      end
    end

    def get_who_should_write
      who_should_write = @standup.users.pluck(:slack_id)
      Rails.logger.info("Should write: #{who_should_write.inspect}")

      create_users_if_any_does_not_exist(who_should_write)

      who_should_write
    end

    def get_whom_to_nofity_result
      whom_to_nofity = @standup.users.where(standup_notifications: true).pluck(:slack_id)
      Rails.logger.info("Whom to notify: #{whom_to_nofity.inspect}")

      create_users_if_any_does_not_exist(whom_to_nofity)

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
      history = Client::Slack.new(@standup.slack_api_token).channels_history(channel: @standup.channel_read_from, oldest: to_timestamp(DateTime.now - 21.hours)) # day before at 9pm
      raise StandardError.new("Something went wrong! #{history.inspect}") if history['ok'].to_s == 'false'
      messages = history['messages']
      Rails.logger.info("Slack messages: #{messages.inspect}")

      if messages.present?
        users_who_wrote = messages.map { |msg| msg['user'] }.uniq
      else
        users_who_wrote = []
      end

      users_who_wrote
    end

    def buzz_all!(didnt_wrote)
      # reset counter who wrote standup
      User.where.not(slack_id: didnt_wrote).update_all(standup_counter: 0)

      increment_standup_counters(didnt_wrote)

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

    def buzz!(user_slack_id)
      count_not_written = User.find_by!(slack_id: user_slack_id).standup_counter

      message = @standup.message_to_user.("[[USER_SLACK_ID]]", "<@#{user_slack_id}>").to_s
      if count_not_written > 1
        message = "#{message}" + @standup.message_to_user_count_not_written.gsub!("[[COUNT_NOT_WRITTEN]]", "#{count_not_written}").to_s
      end

      if Rails.env.production?
        Client::Slack.new(@standup.slack_api_token).chat_postMessage(
          channel: user_slack_id,
          text: message,
          username: @standup.name.to_s + ' checker',
          icon_url: @standup.bot_icon_url
        )
      else
        Rails.logger.info("Slack notification for: #{user_slack_id}")
        Rails.logger.info(message)
      end

      Rails.logger.info("Buzzed user: #{user_slack_id}")
    end

    def notify_about_all_who_didnt_wrote(didnt_wrote, whom_id)
      users_what_didnt_wrote = User.where(slack_id: didnt_wrote).order('standup_counter DESC')

      good_i = 0
      good_text = ''
      warning_i = 0
      warning_text = ''
      danger_i = 0
      danger_text = ''
      users_what_didnt_wrote.each do |user|
        slack_name = "<@#{user.slack_id}>"

        if user.standup_counter < 1
          good_text += ', ' if good_i != 0
          good_text += "#{slack_name}"
          good_i += 1
        elsif user.standup_counter == 1
          warning_text += ', ' if warning_i != 0
          warning_text += "#{slack_name}"
          warning_i += 1
        else # bigger than 1
          danger_text += ', ' if danger_i != 0
          danger_text += "#{slack_name} (#{user.standup_counter}x)"
          danger_i += 1
        end

      end

      Rails.logger.info("Notified about buzzed users: #{whom_id}")

      attachment_payload_good = {
        "color": "good",
        "text": good_text
      }

      attachment_payload_warning = {
        "color": "warning",
        "text": warning_text
      }

      attachment_payload_danger = {
        "color": "danger",
        "text": danger_text
      }

      attachments_payload = {}
      attachments_payload.merge!(0 => attachment_payload_good) if good_text.present?
      attachments_payload.merge!(1 => attachment_payload_warning) if warning_text.present?
      attachments_payload.merge!(2 => attachment_payload_danger) if danger_text.present?

      payload = {
        channel: whom_id,
        text: @standup.message_to_notified.to_s,
        username: @standup.name.to_s + ' bitch',
        icon_url: @standup.bot_icon_url,
        attachments: attachments_payload
      }

      Client::Slack.new(@standup.slack_api_token).chat_postMessage(payload)
    end

    def notify_that_all_wrote(whom_id)
      Rails.logger.info("Notified about all wrote: #{whom_id}")
      Client::Slack.new(@standup.slack_api_token).chat_postMessage(
        channel: whom_id,
        text: @standup.message_all_wrote,
        username: @standup.name.to_s + ' checker',
        icon_url: @standup.bot_icon_happy_url,
        attachments: {
          0 => {
            "color": "good",
            "text": ":tada: :tada: :tada:"
          }
        }
      )
    end

    def to_timestamp(ago)
      timestamp = ago.to_i
      Rails.logger.info("Got timestamp: #{timestamp}")
      timestamp
    end

    private

    def increment_standup_counters(didnt_wrote)
      didnt_wrote.each do |user_who_didnt_wrote_standup|
        user = User.find_by(slack_id: user_who_didnt_wrote_standup)
        if user.nil?
          user = User.create!(slack_id: user_who_didnt_wrote_standup)
        end
        user.increment!(:standup_counter)
        user.standup_counter
      end
    end

    def create_users_if_any_does_not_exist(slack_ids)
      slack_ids.each do |slack_id|
        if User.find_by(slack_id: slack_id).nil?
          User.create!(slack_id: slack_id)
        end
      end
    end

  end
end
