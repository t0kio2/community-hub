class  Api::V1::Auth::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  # アカウント作成とトークン発行を原子化（どちらか失敗でロールバック）
  def create
    build_resource(sign_up_params)

    unless resource.valid?
      return render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end

    access_token = nil
    refresh_raw  = nil

    begin
      ActiveRecord::Base.transaction do
        resource.save!

        access_token, _expires_in = Auth::TokenService.issue_access_for(resource, scope: :user_account)

        device_id = request.headers["X-Device-Id"].presence
        device_name = request.headers["X-Device-Name"].presence
        refresh_raw = Auth::TokenService.issue_refresh_for(
          resource,
          device_id: device_id,
          device_name: device_name,
          ttl: 90.days
        )
      end
    rescue => e
      return render json: { errors: ["Sign up failed", e.message] }, status: :unprocessable_entity
    end

    response.set_header("Authorization", "Bearer #{access_token}")
    render json: {
      account: { id: resource.id, email: resource.email },
      refresh_token: refresh_raw
    }, status: :created
  end
end
