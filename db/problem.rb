class Problem < ActiveRecord::Base
  validates :title,     presence: true
  validates :text,      presence: true
  validates :creator,   presence: true
  validates :reference_point, presence: true
  validates :perfect_point,   presence: true

  has_many :answers,  dependent: :destroy
  has_many :comments, dependent: :destroy, as: :commentable
  has_many :issues,   dependent: :destroy
  has_many :next_problems, class_name: self.to_s, foreign_key: "problem_must_solve_before_id"
  has_many :first_correct_answer, dependent: :destroy

  has_and_belongs_to_many :problem_groups, dependent: :nullify

  belongs_to :problem_must_solve_before, class_name: self.to_s
  belongs_to :creator, foreign_key: "creator_id", class_name: "Member"

  # method: POST
  def self.allowed_to_create_by?(user = nil, action: "")
    case user&.role_id
    when ROLE_ID[:admin], ROLE_ID[:writer]
      true
    else
      false
    end
  end

  # method: GET, PUT, PATCH, DELETE
  def allowed?(by: nil, method:, action: "")
    return self.class.readables(user: by, action: action).to_a.one?{|x| x.id == id } if method == "GET"

    case by&.role_id
    when ROLE_ID[:admin]
      true
    when ROLE_ID[:writer]
      creator_id == by.id
    else
      false
    end
  end

  # method: GET
  scope :readables, -> (user: nil, team: nil, action: "") {
    case user&.role_id
    when ROLE_ID[:admin]
      all
    when ROLE_ID[:writer]
      next all if action.empty?
      next where(creator: user) if action == "problems_comments"
      none
    when ->(role_id) { role_id == ROLE_ID[:participant] || team }
      next none if DateTime.now <= Setting.competition_start_at

      relation = left_outer_joins(problem_must_solve_before: [:first_correct_answer])

      relation.where(problem_must_solve_before_id: nil).or(
        relation.merge(FirstCorrectAnswer.where.not(team_id: nil))
      )
    when ROLE_ID[:viewer]
      all
    else
      none
    end
  }

  def readable_teams
    Team.select{|team| Problem.readables(team: team).find_by(id: id) }
  end
end
