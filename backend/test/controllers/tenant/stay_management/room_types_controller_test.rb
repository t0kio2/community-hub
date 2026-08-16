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

  test "客室タイプがない場合は空状態を表示する" do
    get tenant_stay_room_types_path(@listing)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "客室タイプ"
    assert_includes response.body, "客室タイプがまだ登録されていません"
    assert_select "a[href=?]", new_tenant_stay_room_type_path(@listing), text: "客室タイプを登録"
  end

  test "客室タイプ登録画面に入力項目を表示する" do
    get new_tenant_stay_room_type_path(@listing)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "客室タイプ登録"
    assert_select "form[action=?]", tenant_stay_room_types_path(@listing)
    assert_select "input[name='stay_room_type[name]'][required]"
    assert_select "select[name='stay_room_type[room_kind]'][required]" do
      assert_select "option[value='private_room']", text: "個室"
    end
  end

  test "客室タイプを施設に登録する" do
    assert_difference "@stay_listing.stay_room_types.count", 1 do
      post tenant_stay_room_types_path(@listing), params: {
        stay_room_type: {
          name: "スタンダードツイン",
          description: "シングルベッド2台の客室です",
          room_kind: "private_room",
          capacity: 2,
          status: "draft"
        }
      }
    end

    room_type = @stay_listing.stay_room_types.order(:id).last
    assert_redirected_to tenant_stay_room_types_path(@listing)
    assert_equal "スタンダードツイン", room_type.name
    assert_equal "private_room", room_type.room_kind
    assert_equal 2, room_type.capacity
  end

  test "客室タイプ編集画面に保存済みの値を表示する" do
    room_type = @stay_listing.stay_room_types.create!(
      name: "スタンダードツイン",
      room_kind: "private_room",
      capacity: 2
    )

    get edit_tenant_stay_room_type_path(@listing, room_type)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "客室タイプ編集"
    assert_select "form[action=?]", tenant_stay_room_type_path(@listing, room_type)
    assert_select "input[name='stay_room_type[name]'][value='スタンダードツイン']"
    assert_select "a[aria-current='page'][href=?]", tenant_stay_room_types_path(@listing)
    assert_select "a[aria-current='page'][href=?]", edit_tenant_stay_path(@listing), count: 0
  end

  test "客室タイプの入力が不正な場合は登録画面を再表示する" do
    assert_no_difference "StayRoomType.count" do
      post tenant_stay_room_types_path(@listing), params: {
        stay_room_type: { name: "", room_kind: "", capacity: 0, status: "draft" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']"
    assert_select "input[name='stay_room_type[capacity]'][value='0']"
  end

  test "施設に属する客室タイプを一覧表示する" do
    room_type = @stay_listing.stay_room_types.create!(
      name: "女性専用ドミトリー",
      description: "女性専用の相部屋です",
      room_kind: "shared_room",
      capacity: 1,
      status: "published"
    )

    get tenant_stay_room_types_path(@listing)

    assert_response :success
    assert_select "td", text: /女性専用ドミトリー/
    assert_select "td", text: "相部屋"
    assert_select "a[href=?]", edit_tenant_stay_room_type_path(@listing, room_type), text: "編集"
  end
end
