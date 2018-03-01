class FirstCorrectAnswer < ActiveRecord::Base
  belongs_to :problem
  belongs_to :team
  belongs_to :answer

  validates :team,  presence: true
  validates :answer,  presence: true
  validates :problem, presence: true, uniqueness: true
end
