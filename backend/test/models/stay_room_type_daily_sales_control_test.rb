require "test_helper"

class StayRoomTypeDailySalesControlTest < ActiveSupport::TestCase
  setup do
    tenant = Tenant.create!(name: "販売制御テナント", kana: "ハンバイセイギョテナント", status: "active")
    listing = tenant.listings.create!(title: "テストホテル", listing_type: "stay", status: "draft")
    stay_listing = StayListing.create!(listing: listing)
    @room_type = stay_listing.stay_room_types.create!(name: "ツイン", room_kind: "private_room")
  end

  test "販売上限は0以上の整数で登録する" do
    control = @room_type.stay_room_type_daily_sales_controls.new(stay_date: Date.current, sales_limit: 0)

    assert_predicate control, :valid?

    control.sales_limit = -1
    assert_not control.valid?
  end

  test "同じ客室タイプと宿泊日に複数登録できない" do
    @room_type.stay_room_type_daily_sales_controls.create!(stay_date: Date.current, sales_limit: 1)
    duplicate = @room_type.stay_room_type_daily_sales_controls.new(stay_date: Date.current, sales_limit: 2)

    assert_not duplicate.valid?
  end
end
