require "test_helper"

class Tenant::StayManagement::SalesCalendarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(name: "販売カレンダーテナント", kana: "ハンバイカレンダーテナント", status: "active")
    @account = TenantAccount.create!(
      email: "sales-calendar@example.com", password: "password", password_confirmation: "password"
    )
    TenantMember.create!(tenant: @tenant, account: @account, role: "owner", status: "active")
    @listing = @tenant.listings.create!(title: "カレンダーホテル", listing_type: "stay", status: "draft")
    @stay_listing = StayListing.create!(listing: @listing)
    @room_type = @stay_listing.stay_room_types.create!(
      name: "スタンダードツイン", room_kind: "private_room", capacity: 2
    )
    @rate_plan = @stay_listing.stay_rate_plans.create!(name: "素泊まり", status: "published")
    @rate = StayRoomTypeRate.create!(
      stay_room_type: @room_type, stay_rate_plan: @rate_plan, price_per_night_amount: 10_000
    )
    sign_in @account
  end

  test "指定月の基本料金と日別料金と販売上限を表示する" do
    StayRoomTypeRateDailyPrice.create!(
      stay_room_type_rate: @rate, stay_date: Date.new(2026, 9, 20), price_amount: 15_000
    )
    StayRoomTypeDailySalesControl.create!(
      stay_room_type: @room_type, stay_date: Date.new(2026, 9, 21), sales_limit: 0
    )
    StayRoomTypeDailySalesControl.create!(
      stay_room_type: @room_type, stay_date: Date.new(2026, 9, 22), sales_limit: 3
    )

    get tenant_stay_sales_calendar_path(@listing, month: "2026-09")

    assert_response :success
    assert_select "h1#tenant-page-title", text: "販売カレンダー"
    assert_includes response.body, "2026年9月"
    assert_includes response.body, "スタンダードツイン"
    assert_includes response.body, "素泊まり"
    assert_includes response.body, "¥10,000"
    assert_includes response.body, "¥15,000"
    assert_includes response.body, "個別"
    assert_includes response.body, "販売停止"
    assert_includes response.body, "上限"
    assert_select "a[href=?]", tenant_stay_sales_calendar_path(@listing, month: Date.current.strftime("%Y-%m")), text: "今月"
    assert_select "input[type='submit'][value='移動']"
    assert_select "a[href=?]", tenant_stay_sales_calendar_path(@listing, month: "2026-08"), text: /前月/
    assert_select "a[href=?]", tenant_stay_sales_calendar_path(@listing, month: "2026-10"), text: /翌月/
  end

  test "別施設の日別料金と販売上限を表示しない" do
    other_listing = @tenant.listings.create!(title: "別ホテル", listing_type: "stay", status: "draft")
    other_stay_listing = StayListing.create!(listing: other_listing)
    other_room_type = other_stay_listing.stay_room_types.create!(name: "別施設スイート", room_kind: "private_room")
    other_rate_plan = other_stay_listing.stay_rate_plans.create!(name: "別施設プラン")
    other_rate = StayRoomTypeRate.create!(
      stay_room_type: other_room_type, stay_rate_plan: other_rate_plan, price_per_night_amount: 99_999
    )
    StayRoomTypeRateDailyPrice.create!(
      stay_room_type_rate: other_rate, stay_date: Date.new(2026, 9, 20), price_amount: 88_888
    )

    get tenant_stay_sales_calendar_path(@listing, month: "2026-09")

    assert_response :success
    assert_not_includes response.body, "別施設スイート"
    assert_not_includes response.body, "¥88,888"
  end

  test "客室タイプがない場合は登録への案内を表示する" do
    empty_listing = @tenant.listings.create!(title: "未設定ホテル", listing_type: "stay", status: "draft")
    StayListing.create!(listing: empty_listing)
    sign_in @account

    get tenant_stay_sales_calendar_path(empty_listing, month: "2026-09")

    assert_response :success
    assert_includes response.body, "客室タイプがまだ登録されていません"
    assert_select "a[href=?]", new_tenant_stay_room_type_path(empty_listing), text: "客室タイプを登録"
  end

  test "不正な表示月の場合は当月を表示する" do
    get tenant_stay_sales_calendar_path(@listing, month: "invalid")

    assert_response :success
    assert_select "input[type='month'][value=?]", Date.current.strftime("%Y-%m")
  end

  test "料金セルから日別料金の編集パネルを表示する" do
    stay_date = Date.new(2026, 9, 20)

    get tenant_stay_sales_calendar_path(
      @listing, month: "2026-09", editor: "price", target_id: @rate.id, stay_date: stay_date.iso8601
    )

    assert_response :success
    assert_select "form[action=?]", tenant_stay_sales_calendar_daily_price_path(@listing) do
      assert_select "input[name='stay_room_type_rate_id'][value=?]", @rate.id.to_s
      assert_select "input[name='stay_date'][value=?]", stay_date.iso8601
      assert_select "input[name='daily_price[price_amount]'][value='10000']"
    end
    assert_select "a.sales-calendar__cell-action.is-selected[aria-current='true']", text: /¥10,000/
    assert_includes response.body, "日別料金を保存"
  end

  test "販売上限セルから販売制御の編集パネルを表示する" do
    stay_date = Date.new(2026, 9, 21)

    get tenant_stay_sales_calendar_path(
      @listing, month: "2026-09", editor: "sales", target_id: @room_type.id, stay_date: stay_date.iso8601
    )

    assert_response :success
    assert_select "form[action=?]", tenant_stay_sales_calendar_daily_sales_control_path(@listing)
    assert_select "a.sales-calendar__cell-action.is-selected[aria-current='true']", text: /上限なし/
    assert_includes response.body, "販売上限を保存"
    assert_includes response.body, "販売停止にする"
    assert_includes response.body, "上限なしへ戻す"
  end
end
