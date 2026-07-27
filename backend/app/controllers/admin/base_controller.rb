class Admin::BaseController < ActionController::Base
  include PolicyAuthorization

  protect_from_forgery with: :exception

  before_action :authenticate_admin_account!
  before_action :authorize_active_admin!

  helper_method :current_admin

  layout "admin"

  private

  def current_admin
    @current_admin ||= current_admin_account&.admin
  end

  def authorization_actor
    current_admin
  end

  def authorize_active_admin!
    authorize current_admin, :access?, with: Admin::BasePolicy
  end

  def handle_not_authorized
    unless current_admin&.status == "active"
      return render plain: "このアカウントは利用できません", status: :forbidden
    end

    redirect_to admin_root_path, alert: "この操作を行う権限がありません"
  end

  rescue_from PolicyAuthorization::NotAuthorizedError, with: :handle_not_authorized
end
