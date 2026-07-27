class Tenant::BaseController < ActionController::Base
  include PolicyAuthorization

  protect_from_forgery with: :exception

  before_action :authenticate_tenant_account!
  before_action :authorize_active_tenant_member!

  helper_method :current_tenant_member, :current_tenant_organization

  layout "tenant"

  private

  def current_tenant_member
    @current_tenant_member ||= current_tenant_account&.tenant_member
  end

  def current_tenant_organization
    @current_tenant_organization ||= current_tenant_member&.tenant
  end

  def authorization_actor
    current_tenant_member
  end

  def authorize_active_tenant_member!
    authorize current_tenant_member, :access?, with: Tenant::BasePolicy
  end

  def handle_not_authorized
    unless current_tenant_member&.status == "active"
      return render plain: "このアカウントは利用できません", status: :forbidden
    end

    redirect_to tenant_root_path, alert: "この操作を行う権限がありません"
  end

  rescue_from PolicyAuthorization::NotAuthorizedError, with: :handle_not_authorized
end
