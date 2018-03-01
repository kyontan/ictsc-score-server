require "sinatra/activerecord_helpers"
require "sinatra/json_helpers"
require_relative "../services/account_service"
require_relative "../services/nested_entity"

class ProblemRoutes < Sinatra::Base
  helpers Sinatra::ActiveRecordHelpers
  helpers Sinatra::NestedEntityHelpers
  helpers Sinatra::JSONHelpers
  helpers Sinatra::AccountServiceHelpers

  def remove_secret_info_from(problem:)
    problem.delete('creator_id') unless is_staff?

    problem['creator']&.delete('hashed_password')
    problem['answers']&.each do |answer|
      answer['team']&.delete('registration_code')
    end
  end

  before "/api/problems*" do
    I18n.locale = :en if request.xhr?

    @with_param = (params[:with] || "").split(',') & %w(answers answers-score answers-team issues issues-comments creator comments problem_groups) if request.get?
    @as_option = { methods: [:problem_group_ids] }
  end

  get "/api/problems" do
    @problems = generate_nested_hash(klass: Problem, by: current_user, as_option: @as_option, params: @with_param, apply_filter: !is_staff?).uniq

    if is_participant?
      next json [] if DateTime.now <= Setting.competition_start_at

      show_columns = Problem.column_names - %w(title text)
      @problems = (@problems + Problem.where.not(id: @problems.map{|x| x["id"]}).select(*show_columns).as_json(@as_option)).sort_by{|x| x["id"] }
    end

    solved_teams_count_by_problem = FirstCorrectAnswer \
      .readables(action: "for_count") \
      .inject(Hash.new(0)){|a, fca| a[fca.problem_id] += 1; a}

    cleared_pg_bonuses = Score.cleared_problem_group_bonuses(team_id: current_user&.team_id)

    @problems.each do |p|
      remove_secret_info_from(problem: p)
      p["solved_teams_count"] = solved_teams_count_by_problem[p["id"]] || 0
      p["answers"]&.each do |a|
        if score = a["score"]
          score["bonus_point"]    = cleared_pg_bonuses[score["id"]] || 0
          score["subtotal_point"] = score["point"] + score["bonus_point"]
        end
      end
    end

    json @problems
  end

  before "/api/problems/:id" do
    problems = if request.request_method == "GET"
        Problem.includes(:comments, answers: [:score])
      else
        Problem.includes(:comments)
      end

    @problem = problems.find_by(id: params[:id])

    halt 404 if not @problem&.allowed?(by: current_user, method: request.request_method)
  end

  get "/api/problems/:id" do
    solved_teams_count = FirstCorrectAnswer \
      .where(problem: @problem) \
      .readables(action: "for_count") \
      .count

    @problem = generate_nested_hash(klass: Problem, by: current_user, as_option: @as_option, params: @with_param, id: params[:id], apply_filter: !(is_admin? || is_viewer?))
    remove_secret_info_from(problem: @problem)
    @problem["solved_teams_count"] = solved_teams_count
    @problem["answers"]&.each do |a|
      if score = a["score"]
        s = Score.find(score["id"])

        score["bonus_point"]    = s.bonus_point
        score["subtotal_point"] = s.subtotal_point
      end
    end

    json @problem
  end

  post "/api/problems" do
    halt 403 if not Problem.allowed_to_create_by?(current_user)

    @attrs = params_to_attributes_of(klass: Problem, include: [:problem_group_ids])

    begin
      @problem = Problem.new(@attrs)
    rescue ActiveRecord::RecordNotFound
      status 400
      next json problem_group_ids: "存在しないレコードです"
    end

    if @problem.save
      status 201
      headers "Location" => to("/api/problems/#{@problem.id}")
      json @problem.as_json(@as_option)
    else
      status 400
      json @problem.errors
    end
  end

  update_problem_block = Proc.new do
    if request.put? and not filled_all_attributes_of?(klass: Problem)
      status 400
      next json required: insufficient_attribute_names_of(klass: Problem)
    end

    @attrs = params_to_attributes_of(klass: Problem)
    @problem.attributes = @attrs

    if not @problem.valid?
      status 400
      next json @problem.errors
    end

    begin
      @problem.problem_group_ids = params[:problem_group_ids]
    rescue ActiveRecord::RecordNotFound
      status 400
      next json problem_group_ids: "存在しないレコードです"
    end

    if @problem.save
      json @problem.as_json(@as_option)
    else
      status 400
      json @problem.errors
    end
  end

  put "/api/problems/:id", &update_problem_block
  patch "/api/problems/:id", &update_problem_block

  delete "/api/problems/:id" do
    if @problem.destroy
      status 204
      json status: "success"
    else
      status 500
      json status: "failed"
    end
  end
end
