require "test_helper"

class Api::V1::User::UserProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = UserAccount.create!(
      email: "profile-user@example.com",
      password: "password",
      password_confirmation: "password"
    )
    @user = User.create!(account: @account, status: "active")
    @headers = authenticated_headers(@account)
  end

  test "未ログインではプロフィールを取得できない" do
    get "/api/v1/user/profile"

    assert_response :unauthorized
  end

  test "プロフィール未作成時はnullを返す" do
    get "/api/v1/user/profile", headers: @headers

    assert_response :success
    assert_nil JSON.parse(response.body).fetch("user_profile")
  end

  test "ログイン中ユーザーのプロフィールを取得できる" do
    user_profile = @user.create_user_profile!(
      name: "山田 太郎",
      kana: "ヤマダ タロウ",
      birth_date: Date.new(1995, 4, 12),
      phone: "09012345678",
      avatar_url: "https://example.com/avatar.png"
    )

    get "/api/v1/user/profile", headers: @headers

    assert_response :success
    body = JSON.parse(response.body).fetch("user_profile")
    assert_equal user_profile.id, body.fetch("id")
    assert_equal "山田 太郎", body.fetch("name")
    assert_equal "1995-04-12", body.fetch("birth_date")
  end

  test "プロフィール未作成時は新規作成できる" do
    assert_difference("UserProfile.count", 1) do
      put "/api/v1/user/profile",
          params: {
            user_profile: {
              name: "佐藤 花子",
              kana: "サトウ ハナコ",
              birth_date: "1998-08-20",
              phone: "08012345678",
              avatar_url: "https://example.com/hanako.png"
            }
          },
          headers: @headers
    end

    assert_response :success
    body = JSON.parse(response.body).fetch("user_profile")
    assert_equal "佐藤 花子", body.fetch("name")
    assert_equal @user.id, @user.reload.user_profile.user_id
  end

  test "作成済みプロフィールを更新できる" do
    user_profile = @user.create_user_profile!(name: "更新前")

    assert_no_difference("UserProfile.count") do
      put "/api/v1/user/profile",
          params: {
            user_profile: {
              name: "更新後",
              kana: nil,
              birth_date: nil,
              phone: "09099998888",
              avatar_url: nil
            }
          },
          headers: @headers
    end

    assert_response :success
    body = JSON.parse(response.body).fetch("user_profile")
    assert_equal user_profile.id, body.fetch("id")
    assert_equal "更新後", body.fetch("name")
    assert_equal "09099998888", body.fetch("phone")
  end

  test "名前が空の場合はバリデーションエラーを返す" do
    assert_no_difference("UserProfile.count") do
      put "/api/v1/user/profile",
          params: { user_profile: { name: "" } },
          headers: @headers
    end

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body).fetch("errors"), "Name can't be blank"
  end

  private

  def authenticated_headers(account)
    token, = Auth::TokenService.issue_access_for(account, scope: :user_account)
    { "Authorization" => "Bearer #{token}" }
  end
end
