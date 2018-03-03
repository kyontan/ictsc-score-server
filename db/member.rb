class Member < ActiveRecord::Base
  validates :name,            presence: true
  validates :login,           presence: true, uniqueness: true
  validates :hashed_password, presence: true
  validates :team,            presence: true, if: Proc.new {|member| not member.team_id.nil? }
  validates :team,            presence: true, on: :sign_up
  validates :role,            presence: true
  validates_associated :notification_subscriber

  has_many :marked_scores   , foreign_key: "marker_id" , class_name: "Score"  , dependent: :destroy
  has_many :created_problems, foreign_key: "creator_id", class_name: "Problem", dependent: :destroy

  has_many :comments, dependent: :destroy
  has_many :notices, dependent: :destroy
  has_many :attachments, dependent: :destroy
  has_one :notification_subscriber, dependent: :destroy, as: :subscribable

  belongs_to :team
  belongs_to :role

  before_validation def build_notification_subscriber_if_not_exists
    build_notification_subscriber if not notification_subscriber
    notification_subscriber.valid?
  end

  # For FactoryBot to pass plain password to spec from factory
  attr_accessor :password

  # method: POST
  def self.allowed_to_create_by?(user = nil, action: "")
    case user&.role_id
    when ROLE_ID[:admin], ROLE_ID[:writer], nil # nologin
      true
    else
      false
    end
  end

  # method: GET, PUT, PATCH, DELETE
  def allowed?(method:, by: nil, action: "")
    return self.class.readables(user: by, action: action).exists?(id: id) if method == "GET"

    case by&.role_id
    when ROLE_ID[:admin]
      true
    when ROLE_ID[:writer]
      self.class.readables(user: by, action: action).exists?(id: id)
    when ROLE_ID[:participant]
      return false if method == "DELETE"
      id == by.id
    else # nologin, ...
      false
    end
  end

  # method: GET
  scope :readables, ->(user: nil, action: "") {
    case user&.role_id
    when ROLE_ID[:admin]
      all
    when ROLE_ID[:writer], ROLE_ID[:viewer]
      joins(:role).where("roles.id != ?", ROLE_ID[:admin])
    when ROLE_ID[:participant]
      joins(:role).where("roles.id = ?", ROLE_ID[:participant])
    else # nologin, ...
      none
    end
  }
end
