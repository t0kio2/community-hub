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

  test "公開宿泊施設の宿泊設定を取得できる" do
    listing = listings(:stay)
    listing.update!(status: "published", published_at: Time.current)

    get "/api/v1/public/listings/#{listing.id}"

    assert_response :success
    detail = JSON.parse(response.body).fetch("listing").fetch("detail")
    assert_equal "Asia/Tokyo", detail.fetch("time_zone")
    assert_equal "2026-05-01", detail.fetch("stay_available_starts_on")
    assert_equal "2026-06-01", detail.fetch("stay_available_ends_on")
    assert_equal "禁煙", detail.fetch("house_rules")
    assert_not detail.key?("stay_type")
    assert_not detail.key?("price_per_night")
  end
end
