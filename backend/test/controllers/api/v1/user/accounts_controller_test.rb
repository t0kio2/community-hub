require "test_helper"

class Api::V1::User::AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = UserAccount.create!(
      email: "delete-user@example.com",
      password: "password",
      password_confirmation: "password"
    )
    @user = User.create!(account: @account, status: "active")
    @headers = authenticated_headers(@account)
  end

  test "未ログインではアカウントを削除できない" do
    delete "/api/v1/user/account"

    assert_response :unauthorized
  end

  test "ログイン中ユーザーのアカウントと関連データを削除できる" do
    @user.create_user_profile!(name: "削除 太郎")
    UserRefreshToken.issue!(account: @account, device_id: "delete-test-device", device_name: "browser")

    assert_difference("UserAccount.count", -1) do
      assert_difference("User.count", -1) do
        assert_difference("UserProfile.count", -1) do
          assert_difference("UserRefreshToken.count", -1) do
            delete "/api/v1/user/account", headers: @headers
          end
        end
      end
    end

    assert_response :no_content
    assert_nil Account.find_by(id: @account.id)
  end

  test "ユーザーが未作成のアカウントも削除できる" do
    account = UserAccount.create!(
      email: "delete-account-only@example.com",
      password: "password",
      password_confirmation: "password"
    )

    assert_difference("UserAccount.count", -1) do
      assert_no_difference("User.count") do
        delete "/api/v1/user/account", headers: authenticated_headers(account)
      end
    end

    assert_response :no_content
  end

  private

  def authenticated_headers(account)
    token, = Auth::TokenService.issue_access_for(account, scope: :user_account)
    { "Authorization" => "Bearer #{token}" }
  end
end
