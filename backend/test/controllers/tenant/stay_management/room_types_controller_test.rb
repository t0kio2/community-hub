require "test_helper"

class Tenant::StayManagement::RoomTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(name: "宿泊テナント", kana: "シュクハクテナント", status: "active")
    @account = TenantAccount.create!(
      email: "room-types@example.com",
      password: "password",
      password_confirmation: "password"
    )
    TenantMember.create!(tenant: @tenant, account: @account, role: "owner", status: "active")
    @listing = @tenant.listings.create!(title: "テストホテル", listing_type: "stay", status: "draft")
    @stay_listing = StayListing.create!(listing: @listing)
    sign_in @account
  end

  test "Room Typeがない場合は空状態を表示する" do
    get tenant_stay_room_types_path(@listing)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "Room Type"
    assert_select "a.text-decoration-none[href=?]", new_tenant_stay_room_type_path(@listing) do
      assert_select ".stay-dashboard__empty-state", text: /Room Typeがまだ登録されていません/
    end
    assert_select 'link[rel="stylesheet"][href*="utilities"]', count: 1
    assert_select ".stay-dashboard__badge", text: "登録機能は準備中"
  end

  test "施設に属するRoom Typeを一覧表示する" do
    room_type = @stay_listing.stay_room_types.create!(
      name: "女性専用ドミトリー",
      description: "女性専用の相部屋です",
      room_kind: "shared_room",
      capacity: 1,
      status: "published"
    )

    get tenant_stay_room_types_path(@listing)

    assert_response :success
    assert_select ".stay-room-types__table tbody tr", count: 1
    assert_select "td", text: /女性専用ドミトリー/
    assert_select "td", text: "相部屋"
    assert_select "td", text: "1名"
  end
end
