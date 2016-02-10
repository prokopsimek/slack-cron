class SlackClient

  def self.new
    Slack::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

end