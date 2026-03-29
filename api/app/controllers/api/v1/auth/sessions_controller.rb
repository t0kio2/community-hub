class Api::V1::Auth::SessionsController < Devise::SessionsController

  # APIモードなのでJSON形式のみを受け付ける
  respond_to :json

  def create
    Rails.logger.warn("[LOGIN] headers content_type=#{request.content_type} accept=#{request.headers['Accept']}")
    Rails.logger.warn("[LOGIN] raw_post=#{request.raw_post}")
    Rails.logger.warn("[LOGIN] params=#{params.to_unsafe_h}")
    super
  end

  private

  # ログイン成功時のレスポンス (JWTはヘッダに自動で乗る)
  def respond_with(resource, _opts = {})
    # resource は account が入っている
    if resource&.persisted?
      device_id = request.headers["X-Device-Id"].presence
      device_name = request.headers["X-Device-Name"].presence

      # リフレッシュトークン発行
      refresh_raw = Auth::TokenService.issue_refresh_for(
        resource, # account オブジェクト
        device_id: device_id,
        device_name: device_name,
        ttl: 90.days
      )

      render json: {
        account: { id: resource.id, email: resource.email },
        refresh_token: refresh_raw
      }, status: :ok

    else
      # 認証失敗のレスポンス（Devise標準のFailureAppが動くため、ここは保険）
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  # ログアウト成功時のレスポンス（Deviseの版差異に備え可変引数を許容）
  def respond_to_on_destroy(*_args)
    # ログアウト時にリフレッシュトークンも無効化
    if current_user_account && (did = request.headers["X-Device-Id"]).present?
      # active スコープを使って効率的に検索
      rec = current_user_account.user_refresh_tokens.active.find_by(device_id: did)
      rec&.update!(revoked_at: Time.current)
    end

    head :no_content
  end
end
