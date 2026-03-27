class Accounts::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      # サインアップ成功時にアクセストークンとリフレッシュトークンを発行
      access_token, _expires_in = Auth::TokenService.issue_access_for(resource, scope: :account)
      response.set_header("Authorization", "Bearer #{access_token}")

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
      }, status: :created
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end

