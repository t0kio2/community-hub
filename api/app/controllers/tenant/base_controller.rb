class Tenant::BaseController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :authenticate_tenant_account!

  helper_method :current_tenant_member, :current_tenant_organization

  layout 'tenant'

  private

  def current_tenant_member
    @current_tenant_member ||= current_tenant_account&.tenant_member
  end

  def current_tenant_organization
    @current_tenant_organization ||= current_tenant_member&.tenant
  end
end
