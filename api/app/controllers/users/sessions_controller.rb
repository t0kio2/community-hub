class Users::SessionsController < Devise::SessionsController
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
      render json: {
        user: {
          id: resource.id,
          email: resource.email
        }
      },
      status: :ok
    else
      render json: {
        errors: [ "Invalid login" ],
        status: :unauthorized
      }
    end
  end

  def respond_to_an_destroy
    head :no_content
  end
end
