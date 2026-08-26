require "test_helper"

class StayRoomTypeRateDailyPriceTest < ActiveSupport::TestCase
  setup do
    tenant = Tenant.create!(name: "日別料金テナント", kana: "ヒベツリョウキンテナント", status: "active")
    listing = tenant.listings.create!(title: "テストホテル", listing_type: "stay", status: "draft")
    stay_listing = StayListing.create!(listing: listing)
    room_type = stay_listing.stay_room_types.create!(name: "ツイン", room_kind: "private_room")
    rate_plan = stay_listing.stay_rate_plans.create!(name: "素泊まり")
    @rate = StayRoomTypeRate.create!(
      stay_room_type: room_type, stay_rate_plan: rate_plan, price_per_night_amount: 10_000
    )
  end

  test "日別料金は1円以上の整数で登録する" do
    price = @rate.stay_room_type_rate_daily_prices.new(stay_date: Date.current, price_amount: 12_000)

    assert_predicate price, :valid?

    price.price_amount = 0
    assert_not price.valid?
  end

  test "同じRoom Type別料金と宿泊日に複数登録できない" do
    @rate.stay_room_type_rate_daily_prices.create!(stay_date: Date.current, price_amount: 12_000)
    duplicate = @rate.stay_room_type_rate_daily_prices.new(stay_date: Date.current, price_amount: 13_000)

    assert_not duplicate.valid?
  end
end
