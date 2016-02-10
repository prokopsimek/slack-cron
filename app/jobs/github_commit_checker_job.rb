class GithubCommitCheckerJob
  include Sidekiq::Worker
  def perform
    GithubChecker.check_commits_count_for_yesterday!
  end
end