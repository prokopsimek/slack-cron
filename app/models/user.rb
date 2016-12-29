class User < ActiveRecord::Base

  validates :name, :slack_id, presence: true
  validates :name, uniqueness: true

  belongs_to :standup
end
