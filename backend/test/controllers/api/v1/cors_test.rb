require "test_helper"

class Api::V1::CorsTest < ActionDispatch::IntegrationTest
  test "許可されたoriginのpreflightにCORSヘッダを返す" do
    process :options,
            "/api/v1/public/listings",
            headers: {
              "Origin" => "http://localhost:3000",
              "Access-Control-Request-Method" => "GET"
            }

    assert_response :no_content
    assert_equal "http://localhost:3000", response.headers["Access-Control-Allow-Origin"]
    assert_includes response.headers["Access-Control-Allow-Headers"], "Authorization"
    assert_includes response.headers["Access-Control-Expose-Headers"], "Authorization"
  end

  test "通常のAPIレスポンスでもAuthorizationヘッダを公開する" do
    get "/api/v1/public/listings", headers: { "Origin" => "http://localhost:3000" }

    assert_response :success
    assert_equal "http://localhost:3000", response.headers["Access-Control-Allow-Origin"]
    assert_equal "Authorization", response.headers["Access-Control-Expose-Headers"]
  end

  test "ログインAPIレスポンスでもAuthorizationヘッダを公開する" do
    UserAccount.create!(
      email: "cors-login@example.com",
      password: "password",
      password_confirmation: "password"
    )

    post "/api/v1/auth/sign_in",
         params: {
           user_account: {
             email: "cors-login@example.com",
             password: "password"
           }
         },
         as: :json,
         headers: {
           "Origin" => "http://localhost:3000",
           "X-Device-Id" => "cors-test-device",
           "X-Device-Name" => "browser"
         }

    assert_response :success
    assert response.headers["Authorization"].present?
    assert_equal "http://localhost:3000", response.headers["Access-Control-Allow-Origin"]
    assert_equal "Authorization", response.headers["Access-Control-Expose-Headers"]
  end
end
