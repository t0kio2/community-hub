class Admin::SessionsController < Devise::SessionsController
  respond_to :html

  # HTMLログインフォームを表示
  def new
    super

  rescue ActionView::MissingTemplate
    render template: 'admin_accounts/sessions/new'
  end

  # ログイン成功後のリダイレクト先
  def after_sign_in_path_for(resource)
    admin_root_path
  end

  # ログアウト後のリダイレクト先
  def after_sign_out_path_for(resource_or_scope)
    flash[:notice] = 'ログアウトしました'
    new_admin_account_session_path
  end
end
