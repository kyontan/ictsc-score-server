require 'redis'
require 'json'

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
  has_one :first_correct_answer, dependent: :destroy

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

      where(problem_must_solve_before_id: Problem.solvecache(filter: true).keys + [nil])
    when ROLE_ID[:viewer]
      all
    else
      none
    end
  }

  def readable_teams
    Team.select{|team| Problem.readables(team: team).find_by(id: id) }
  end

  def self.calccache
    data = Answer \
      .all \
      .joins(:score, :problem) \
      .select(:problem_id, :team_id, :created_at) \
      .where("scores.point >= problems.reference_point") \
      .to_a \
      .group_by{|e| [e.problem_id, e.team_id]}

    cache = {}
    data.each{|key, ans| data[key] = ans.max_by(&:created_at)} \
      .map{|(k, v), ans| cache[k] = (cache[k] || []) + [[v.to_s, ans.created_at.to_s]]}

    cache.to_json
  end

  def self.solvecache(filter: false)
    cache = JSON.parse(Problem.redis_client.get("solvecache") || self.calccache)
    if filter
      cache = cache.select{|k, v| v.map{|e| DateTime.parse(e[1]) <= DateTime.now - Setting.answer_reply_delay_sec.seconds}.any?}
    end
    cache
  end

  def self.add_solvecache(k, v)
    cache = JSON.parse(Problem.redis_client.get("solvecache") || self.calccache)
    cache[k] = (cache[k] || []) + [v] if cache.keys.include?(k) && !cache[k].include?(v)
    Problem.redis_client.set "solvecache", cache.to_json
  end

  def self.del_solvecache(k, v)
    cache = JSON.parse(Problem.redis_client.get("solvecache") || self.calccache)
    cache[k] = cache[k].select{|e| e[0] != v[0]} if cache.keys.include?(k)
    Problem.redis_client.set "solvecache", cache.to_json
  end

  def self.redis_client
    @redis ||= Redis.new
  end

  self.redis_client.del "solvecache"
end
