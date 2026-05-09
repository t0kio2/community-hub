require "test_helper"

class Api::V1::Auth::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "新規登録時にユーザーも作成する" do
    assert_difference("UserAccount.count", 1) do
      assert_difference("User.count", 1) do
        post "/api/v1/auth",
             params: {
               user_account: {
                 email: "new-user@example.com",
                 password: "password",
                 password_confirmation: "password"
               }
             },
             as: :json,
             headers: {
               "X-Device-Id" => "registration-test-device",
               "X-Device-Name" => "browser"
             }
      end
    end

    assert_response :created
    account = UserAccount.find_by!(email: "new-user@example.com")
    assert_equal account.id, account.user.account_id
    assert response.headers["Authorization"].present?
  end
end
