class Answer < ActiveRecord::Base
  validates :problem, presence: true
  validates :team,    presence: true
  validates :text,    presence: true
  validates :score,   presence: true, if: Proc.new {|answer| not answer&.score&.id.nil? }

  belongs_to :problem
  has_one :score,     dependent: :destroy
  belongs_to :team

  def notification_payload(state: :created, **data)
    payload = super
    payload[:data].merge!(team_id: team_id, problem_id: problem_id)
    payload
  end

  # method: POST
  def self.allowed_to_create_by?(user = nil, action: "")
    case user&.role_id
    when ROLE_ID[:admin], ROLE_ID[:participant]
      true
    else # nologin, ...
      false
    end
  end

  # method: GET, PUT, PATCH, DELETE
  def allowed?(method:, by: nil, action: "")
    return self.class.readables(user: by, action: action).exists?(id: id) if method == "GET"

    case by&.role_id
    when ROLE_ID[:admin]
      true
    else # nologin, ...
      false
    end
  end

  # method: GET
  scope :readables, ->(user: nil, action: "") {
    case user&.role_id
    when ROLE_ID[:admin], ROLE_ID[:writer], ROLE_ID[:viewer]
      all
    when ROLE_ID[:participant]
      where(team: user.team)
    else # nologin, ...
      none
    end
  }
end
