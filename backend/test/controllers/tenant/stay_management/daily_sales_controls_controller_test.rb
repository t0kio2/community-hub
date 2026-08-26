require "test_helper"

class Tenant::StayManagement::DailySalesControlsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(name: "販売上限管理テナント", kana: "ハンバイジョウゲンカンリテナント", status: "active")
    @account = TenantAccount.create!(
      email: "daily-sales-controls@example.com", password: "password", password_confirmation: "password"
    )
    TenantMember.create!(tenant: @tenant, account: @account, role: "owner", status: "active")
    @listing = @tenant.listings.create!(title: "在庫ホテル", listing_type: "stay", status: "draft")
    stay_listing = StayListing.create!(listing: @listing)
    @room_type = stay_listing.stay_room_types.create!(name: "ドミトリー", room_kind: "shared_room", capacity: 1)
    @stay_date = Date.new(2026, 9, 21)
    sign_in @account
  end

  test "日別販売上限を登録して販売停止へ更新する" do
    assert_difference "StayRoomTypeDailySalesControl.count", 1 do
      patch tenant_stay_sales_calendar_daily_sales_control_path(@listing), params: {
        stay_room_type_id: @room_type.id,
        stay_date: @stay_date.iso8601,
        daily_sales_control: { sales_limit: 3 }
      }
    end

    control = @room_type.stay_room_type_daily_sales_controls.find_by!(stay_date: @stay_date)
    assert_equal 3, control.sales_limit
    assert_equal "販売上限を設定しました", flash[:notice]

    sign_in @account
    patch tenant_stay_sales_calendar_daily_sales_control_path(@listing), params: {
      stay_room_type_id: @room_type.id,
      stay_date: @stay_date.iso8601,
      daily_sales_control: { sales_limit: 0 }
    }
    assert_equal 0, control.reload.sales_limit
    assert_equal "販売停止に設定しました", flash[:notice]
  end

  test "日別販売制御を削除して上限なしへ戻す" do
    @room_type.stay_room_type_daily_sales_controls.create!(stay_date: @stay_date, sales_limit: 3)

    assert_difference "StayRoomTypeDailySalesControl.count", -1 do
      delete tenant_stay_sales_calendar_daily_sales_control_path(@listing), params: {
        stay_room_type_id: @room_type.id, stay_date: @stay_date.iso8601
      }
    end

    assert_redirected_to tenant_stay_sales_calendar_path(@listing, month: "2026-09")
    assert_equal "販売上限なしへ戻しました", flash[:notice]
  end

  test "別施設のRoom Typeは更新できない" do
    other_listing = @tenant.listings.create!(title: "別ホテル", listing_type: "stay", status: "draft")
    other_stay_listing = StayListing.create!(listing: other_listing)
    other_room_type = other_stay_listing.stay_room_types.create!(name: "別施設客室", room_kind: "private_room")

    assert_no_difference "StayRoomTypeDailySalesControl.count" do
      patch tenant_stay_sales_calendar_daily_sales_control_path(@listing), params: {
        stay_room_type_id: other_room_type.id,
        stay_date: @stay_date.iso8601,
        daily_sales_control: { sales_limit: 2 }
      }
    end
    assert_response :not_found
  end
end
