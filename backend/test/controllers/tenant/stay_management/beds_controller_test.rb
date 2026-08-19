require "test_helper"

class Tenant::StayManagement::BedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(name: "宿泊テナント", kana: "シュクハクテナント", status: "active")
    @account = TenantAccount.create!(
      email: "beds@example.com",
      password: "password",
      password_confirmation: "password"
    )
    TenantMember.create!(tenant: @tenant, account: @account, role: "owner", status: "active")
    @listing = @tenant.listings.create!(title: "テストホテル", listing_type: "stay", status: "draft")
    @stay_listing = StayListing.create!(listing: @listing)
    @room_type = @stay_listing.stay_room_types.create!(
      name: "女性専用ドミトリー",
      room_kind: "shared_room",
      capacity: 1
    )
    @room = @stay_listing.stay_rooms.create!(name: "ドミトリーA", stay_room_type: @room_type)
    sign_in @account
  end

  test "相部屋の編集画面でベッドを管理できる" do
    get edit_tenant_stay_room_path(@listing, @room)

    assert_response :success
    assert_includes response.body, "ベッド管理"
    assert_select "a[href=?]", new_tenant_stay_room_bed_path(@listing, @room), text: /ベッドを追加/
  end

  test "客室一覧でベッドの割当て状況を確認できる" do
    @room.stay_beds.create!(name: "ベッド1", active: true)
    @room.stay_beds.create!(name: "ベッド2", active: false)

    get tenant_stay_rooms_path(@listing)

    assert_response :success
    assert_includes response.body, "1 / 2床 利用可能"
    assert_select "a[href=?]",
                  edit_tenant_stay_room_path(@listing, @room, anchor: "stay-beds-section"),
                  text: "ベッドを管理"
  end

  test "ベッドを客室へ登録する" do
    assert_difference "@room.stay_beds.count", 1 do
      post tenant_stay_room_beds_path(@listing, @room, format: :turbo_stream), params: {
        stay_bed: { name: "ベッド1", active: true, notes: "窓側" }
      }
    end

    assert_response :success
    assert_equal "窓側", @room.stay_beds.find_by!(name: "ベッド1").notes
  end

  test "別施設の客室にはベッドを登録できない" do
    other_listing = @tenant.listings.create!(title: "別ホテル", listing_type: "stay", status: "draft")
    other_stay_listing = StayListing.create!(listing: other_listing)
    other_room = other_stay_listing.stay_rooms.create!(name: "別施設の客室")

    assert_no_difference "StayBed.count" do
      post tenant_stay_room_beds_path(@listing, other_room), params: {
        stay_bed: { name: "不正なベッド", active: true }
      }
    end

    assert_response :not_found
  end
end
