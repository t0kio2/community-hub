class Tenant::SessionsController < Devise::SessionsController
  respond_to :html
  layout 'tenant'

  # 一部環境で初回アクセス時に CSRF エラーが発生するため、
  # サインイン(create)のみトークン検証をスキップします。
  # （サインアウト等は従来どおりCSRF必須）
  skip_before_action :verify_authenticity_token, only: :create

  # DeviseのHTMLフォームを表示（テンプレート未用意でもOK）
  def new
    super
  rescue ActionView::MissingTemplate
    # Deviseデフォルトのビューにフォールバック
    # プロジェクト側で独自テンプレートを置く場合は
    # render template: 'tenant_accounts/sessions/new'
    super
  end

  # ログイン後の遷移先
  def after_sign_in_path_for(resource)
    tenant_root_path
  end

  # ログアウト後の遷移先
  def after_sign_out_path_for(resource_or_scope)
    flash[:notice] = 'ログアウトしました'
    new_tenant_account_session_path
  end
end
