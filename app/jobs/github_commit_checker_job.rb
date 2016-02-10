class GithubCommitCheckerJob
  include Sidekiq::Worker
  def perform
    Rails.logger.info('Github checker processed!')
    GithubChecker.check_commits_count_for_yesterday!
  end
end