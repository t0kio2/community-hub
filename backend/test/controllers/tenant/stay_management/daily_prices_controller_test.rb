require "test_helper"

class Tenant::StayManagement::DailyPricesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(name: "日別料金管理テナント", kana: "ヒベツリョウキンカンリテナント", status: "active")
    @account = TenantAccount.create!(
      email: "daily-prices@example.com", password: "password", password_confirmation: "password"
    )
    TenantMember.create!(tenant: @tenant, account: @account, role: "owner", status: "active")
    @listing = @tenant.listings.create!(title: "料金ホテル", listing_type: "stay", status: "draft")
    stay_listing = StayListing.create!(listing: @listing)
    room_type = stay_listing.stay_room_types.create!(name: "ツイン", room_kind: "private_room")
    rate_plan = stay_listing.stay_rate_plans.create!(name: "素泊まり")
    @rate = StayRoomTypeRate.create!(
      stay_room_type: room_type, stay_rate_plan: rate_plan, price_per_night_amount: 10_000
    )
    @stay_date = Date.new(2026, 9, 20)
    sign_in @account
  end

  test "日別料金を登録して更新する" do
    assert_difference "StayRoomTypeRateDailyPrice.count", 1 do
      patch tenant_stay_sales_calendar_daily_price_path(@listing), params: {
        stay_room_type_rate_id: @rate.id,
        stay_date: @stay_date.iso8601,
        daily_price: { price_amount: 15_000 }
      }
    end

    price = @rate.stay_room_type_rate_daily_prices.find_by!(stay_date: @stay_date)
    assert_redirected_to tenant_stay_sales_calendar_path(@listing, month: "2026-09")
    assert_equal 15_000, price.price_amount

    sign_in @account
    assert_no_difference "StayRoomTypeRateDailyPrice.count" do
      patch tenant_stay_sales_calendar_daily_price_path(@listing), params: {
        stay_room_type_rate_id: @rate.id,
        stay_date: @stay_date.iso8601,
        daily_price: { price_amount: 18_000 }
      }
    end
    assert_equal 18_000, price.reload.price_amount
  end

  test "日別料金を削除して基本料金へ戻す" do
    @rate.stay_room_type_rate_daily_prices.create!(stay_date: @stay_date, price_amount: 15_000)

    assert_difference "StayRoomTypeRateDailyPrice.count", -1 do
      delete tenant_stay_sales_calendar_daily_price_path(@listing), params: {
        stay_room_type_rate_id: @rate.id, stay_date: @stay_date.iso8601
      }
    end

    assert_redirected_to tenant_stay_sales_calendar_path(@listing, month: "2026-09")
    assert_equal "基本料金へ戻しました", flash[:notice]
  end

  test "別施設のRoom Type別料金は更新できない" do
    other_listing = @tenant.listings.create!(title: "別ホテル", listing_type: "stay", status: "draft")
    other_stay_listing = StayListing.create!(listing: other_listing)
    other_room_type = other_stay_listing.stay_room_types.create!(name: "別施設客室", room_kind: "private_room")
    other_plan = other_stay_listing.stay_rate_plans.create!(name: "別施設プラン")
    other_rate = StayRoomTypeRate.create!(
      stay_room_type: other_room_type, stay_rate_plan: other_plan, price_per_night_amount: 20_000
    )

    assert_no_difference "StayRoomTypeRateDailyPrice.count" do
      patch tenant_stay_sales_calendar_daily_price_path(@listing), params: {
        stay_room_type_rate_id: other_rate.id,
        stay_date: @stay_date.iso8601,
        daily_price: { price_amount: 30_000 }
      }
    end
    assert_response :not_found
  end
end
