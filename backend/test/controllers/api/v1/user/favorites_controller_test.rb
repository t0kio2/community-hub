require "test_helper"

class Api::V1::User::FavoritesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = UserAccount.create!(
      email: "favorite-user@example.com",
      password: "password",
      password_confirmation: "password"
    )
    @user = User.create!(account: @account, status: "active")
    @headers = authenticated_headers(@account)
  end

  test "未ログインではお気に入り一覧を取得できない" do
    get "/api/v1/user/favorites"

    assert_response :unauthorized
  end

  test "ログイン中ユーザーのお気に入り一覧を取得できる" do
    favorite = @user.favorites.create!(listing: listings(:job))

    get "/api/v1/user/favorites", headers: @headers

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal favorite.id, body.fetch("favorites").first.fetch("id")
    assert_equal listings(:job).title, body.fetch("favorites").first.fetch("listing").fetch("title")
  end

  test "公開掲載をお気に入りに追加できる" do
    assert_difference("@user.favorites.count", 1) do
      post "/api/v1/user/favorites",
           params: { listing_id: listings(:job).id },
           headers: @headers
    end

    assert_response :created
    assert_equal listings(:job), @user.favorites.order(:created_at).last.listing
  end

  test "下書き掲載はお気に入りに追加できない" do
    assert_no_difference("@user.favorites.count") do
      post "/api/v1/user/favorites",
           params: { listing_id: listings(:stay).id },
           headers: @headers
    end

    assert_response :not_found
  end

  test "他ユーザーのお気に入りは削除できない" do
    other_account = UserAccount.create!(
      email: "favorite-other@example.com",
      password: "password",
      password_confirmation: "password"
    )
    other_user = User.create!(account: other_account, status: "active")
    favorite = other_user.favorites.create!(listing: listings(:job))

    assert_no_difference("Favorite.count") do
      delete "/api/v1/user/favorites/#{favorite.id}", headers: @headers
    end

    assert_response :not_found
  end

  test "自分のお気に入りを削除できる" do
    favorite = @user.favorites.create!(listing: listings(:job))

    assert_difference("@user.favorites.count", -1) do
      delete "/api/v1/user/favorites/#{favorite.id}", headers: @headers
    end

    assert_response :no_content
  end

  private

  def authenticated_headers(account)
    token, = Auth::TokenService.issue_access_for(account, scope: :user_account)
    { "Authorization" => "Bearer #{token}" }
  end
end
