require "sinatra/activerecord_helpers"
require "sinatra/json_helpers"
require_relative "../services/account_service"

class NoticeRoutes < Sinatra::Base
  helpers Sinatra::ActiveRecordHelpers
  helpers Sinatra::JSONHelpers
  helpers Sinatra::AccountServiceHelpers

  before "/api/notices*" do
    I18n.locale = :en if request.xhr?
  end

  get "/api/notices" do
    @notices = Notice.accessible_resources(user_and_method)
    json @notices
  end

  before "/api/notices/:id" do
    @notice = Notice.accessible_resources(user_and_method) \
                      .find_by(id: params[:id])
    halt 404 if not @notice
  end

  get "/api/notices/:id" do
    json @notice
  end

  post "/api/notices" do
    halt 403 if not Notice.allowed_to_create_by?(current_user)

    @attrs = attribute_values_of_class(Notice)
    @attrs[:member_id] = current_user.id
    @notice = Notice.new(@attrs)

    if @notice.save
      status 201
      headers "Location" => to("/api/notices/#{@notice.id}")
      json @notice
    else
      status 400
      json @notice.errors
    end
  end

  update_notice_block = Proc.new do
    if request.put? and not satisfied_required_fields?(Notice)
      halt 400, { required: insufficient_fields(Notice) }.to_json
    end

    @attrs = attribute_values_of_class(Notice)
    @notice.attributes = @attrs

    halt 400, json(@notice.errors) if not @notice.valid?

    if @notice.save
      json @notice
    else
      status 400
      json @notice.errors
    end
  end

  put "/api/notices/:id", &update_notice_block
  patch "/api/notices/:id", &update_notice_block

  delete "/api/notices/:id" do
    if @notice.destroy
      status 204
      json status: "success"
    else
      status 500
      json status: "failed"
    end
  end
end