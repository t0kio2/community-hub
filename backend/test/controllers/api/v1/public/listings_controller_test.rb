require "test_helper"

class Api::V1::Public::ListingsControllerTest < ActionDispatch::IntegrationTest
  test "未ログインでも公開掲載一覧を取得できる" do
    get "/api/v1/public/listings"

    assert_response :success
    body = JSON.parse(response.body)
    titles = body.fetch("listings").map { |listing| listing.fetch("title") }

    assert_includes titles, listings(:job).title
    assert_not_includes titles, listings(:stay).title
  end

  test "未ログインでも公開掲載詳細を取得できる" do
    get "/api/v1/public/listings/#{listings(:job).id}"

    assert_response :success
    body = JSON.parse(response.body)
    listing = body.fetch("listing")

    assert_equal listings(:job).id, listing.fetch("id")
    assert_equal "job", listing.fetch("listing_type")
    assert_equal "東京都", listing.fetch("detail").fetch("work_area")
  end

  test "下書き掲載詳細は取得できない" do
    get "/api/v1/public/listings/#{listings(:stay).id}"

    assert_response :not_found
  end
end
