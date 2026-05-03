class Api::V1::User::BaseController < ActionController::API
  prepend_before_action :set_json_format
  before_action :authenticate_user_account!

  private

  def set_json_format
    request.format = :json
  end

  def current_user
    @current_user ||= current_user_account.user
  end
end
