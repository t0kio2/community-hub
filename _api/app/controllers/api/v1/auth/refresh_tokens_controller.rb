class Api::V1::Auth::RefreshTokensController < ApplicationController
  # アクセストークン不要。リフレッシュトークンで認証する。
  skip_before_action :authenticate_user!, raise: false rescue nil

  # POST /api/v1/auth/refresh
  # body: { refresh_token: "..." }
  def create
    raw = params[:refresh_token].to_s
    return render json: { error: "refresh_token required" }, status: :bad_request if raw.blank?

    begin
      user, access_token, expires_in, refresh_raw = Auth::TokenService.refresh_with(raw, ttl: 90.days)
      response.set_header("Authorization", "Bearer #{access_token}")

      render json: {
        user: { id: user.id, email: user.email },
        refresh_token: refresh_raw,
        access_token_expires_in: expires_in
      }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { error: "invalid refresh_token" }, status: :unauthorized
    rescue => e
      render json: { error: e.message }, status: :unauthorized
    end
  end

  # DELETE /api/v1/auth/refresh (ボディ: { refresh_token })
  # 端末単位でリフレッシュ失効
  def destroy
    raw = params[:refresh_token].to_s
    return head :no_content if raw.blank?

    rec = UserRefreshToken.find_by(token_digest: UserRefreshToken.digest_for(raw))
    if rec
      rec.update(revoked_at: Time.current)
    end
    head :no_content
  end
end
