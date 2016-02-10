class GithubClient

  def self.new
    Octokit::Client.new(access_token: ENV['GITHUB_API_TOKEN'])
  end

end
