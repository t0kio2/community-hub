class Admin::BaseController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :authenticate_admin_account!

  layout -> { false } # 最小構成（必要ならレイアウトを用意）
end

