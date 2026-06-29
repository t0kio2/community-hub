class Api::V1::User::AccountsController < Api::V1::User::BaseController
  def destroy
    current_user_account.destroy!

    head :no_content
  end
end
