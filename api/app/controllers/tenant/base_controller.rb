class Tenant::BaseController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :authenticate_tenant_account!

  layout 'tenant'
end
