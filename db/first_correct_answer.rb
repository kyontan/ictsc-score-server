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

  scope :readables, ->() {
    joins(:answer).where("answers.created_at <= :time", { time: DateTime.now - Setting.answer_reply_delay_sec.seconds})
  }
end
