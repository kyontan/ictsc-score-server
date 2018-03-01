class FirstCorrectAnswer < ActiveRecord::Base
  belongs_to :problem
  belongs_to :team
  belongs_to :answer

  validates :team,  presence: true
  validates :answer,  presence: true
  validates :problem, presence: true

  scope :reply_delay, ->() {
     where('answers.created_at <= :time', { time:  DateTime.now - Setting.answer_reply_delay_sec.seconds})
  }

  scope :readables, ->(user: nil, team: nil, action: "") {    
    next none if DateTime.now <= Setting.competition_start_at

    next joins(:answer).reply_delay if action == "for_count"

    rel = joins(:problem).where(problems: {team_private: false}).joins(:answer).reply_delay
    next rel.or(joins(:problem).where(problems: {team_private: true}, team: user.team).joins(:answer).reply_delay) if user
    rel
  }
end