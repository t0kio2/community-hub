class Accounts::SessionsController < Devise::SessionsController
  respond_to :json

  def create
    Rails.logger.warn("[LOGIN] headers content_type=#{request.content_type} accept=#{request.headers['Accept']}")
    Rails.logger.warn("[LOGIN] raw_post=#{request.raw_post}")
    Rails.logger.warn("[LOGIN] params=#{params.to_unsafe_h}")
    super
  end

  private

  def respond_with(resource, _opts = {})
    if resource&.persisted?
      # リフレッシュトークンを発行（アクセスJWTはdevise-jwtが自動で付与）
      device_id = request.headers["X-Device-Id"].presence
      device_name = request.headers["X-Device-Name"].presence
      refresh_raw = Auth::TokenService.issue_refresh_for(
        resource,
        device_id: device_id,
        device_name: device_name,
        ttl: 90.days
      )

      render json: {
        account: { id: resource.id, email: resource.email },
        refresh_token: refresh_raw
      }, status: :ok
    else
      render json: { errors: ["Invalid login"], status: :unauthorized }
    end
  end

  # Devise の API モード向け: HTML 応答分岐を使わず 204 を返す
  def respond_to_on_destroy
    if current_account && (did = request.headers["X-Device-Id"]).present?
      if (rec = UserRefreshToken.find_by(account_id: current_account.id, device_id: did, revoked_at: nil))
        rec.update(revoked_at: Time.current)
      end
    end
    head :no_content
  end
end

