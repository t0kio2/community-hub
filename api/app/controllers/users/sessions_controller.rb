class Users::SessionsController < Devise::SessionsController
  respond_to :json

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
