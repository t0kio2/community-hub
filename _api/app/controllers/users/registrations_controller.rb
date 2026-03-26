class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      # サインアップ成功時にアクセストークンとリフレッシュトークンを発行
      # アクセスJWTはヘッダ Authorization に設定
      access_token, expires_in = Auth::TokenService.issue_access_for(resource)
      response.set_header("Authorization", "Bearer #{access_token}")

      # リフレッシュトークンはJSONで返す（device情報は任意ヘッダ）
      device_id = request.headers["X-Device-Id"].presence
      device_name = request.headers["X-Device-Name"].presence
      refresh_raw = Auth::TokenService.issue_refresh_for(
        resource,
        device_id: device_id,
        device_name: device_name,
        ttl: 90.days
      )

      render json: {
        user: { id: resource.id, email: resource.email },
        refresh_token: refresh_raw
      }, status: :created
    else
      render json: {
        errors: resource.errors.full_messages
        },
        status: :unprocessable_entity
    end
  end
end
