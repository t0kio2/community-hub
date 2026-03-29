class Api::V1::HelloController < Api::V1::BaseController
  def index
    render json: {
      message: "hello world",
      account: {
        id: current_user_account.id,
        email: current_user_account.email
      }
    }
  end
end

