class Client::Slack

  def self.new(api_token)
    Slack::Client.new(token: api_token)
  end

end
