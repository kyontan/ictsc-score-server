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
    case user&.role_id
    when ROLE_ID[:admin], ROLE_ID[:writer], ROLE_ID[:viewer]
      all
    when ROLE_ID[:participant]
      next none if DateTime.now <= Setting.competition_start_at

      rel = joins(:answer).reply_delay
      next rel if action == "for_count"
  
      rel_public = rel.joins(:problem).where(problems: {team_private: false})
      next rel_public unless user

      rel_public.or(
        rel.joins(:problem).where(problems: {team_private: true}, team: user.team)
      )
    else
      none
    end
  }
end