require "test_helper"

class Tenant::StayManagement::RoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(name: "宿泊テナント", kana: "シュクハクテナント", status: "active")
    @account = TenantAccount.create!(
      email: "rooms@example.com",
      password: "password",
      password_confirmation: "password"
    )
    TenantMember.create!(tenant: @tenant, account: @account, role: "owner", status: "active")
    @listing = @tenant.listings.create!(title: "テストホテル", listing_type: "stay", status: "draft")
    @stay_listing = StayListing.create!(listing: @listing)
    @room_type = @stay_listing.stay_room_types.create!(
      name: "スタンダードツイン",
      room_kind: "private_room",
      capacity: 2
    )
    sign_in @account
  end

  test "客室がない場合は空状態を表示する" do
    get tenant_stay_rooms_path(@listing)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "割当て客室管理"
    assert_includes response.body, "客室がまだ登録されていません"
    assert_select "a[href=?]", new_tenant_stay_room_path(@listing), text: /客室を登録/
  end

  test "客室登録画面に同じ施設の客室タイプを表示する" do
    other_listing = @tenant.listings.create!(title: "別ホテル", listing_type: "stay", status: "draft")
    other_stay_listing = StayListing.create!(listing: other_listing)
    other_room_type = other_stay_listing.stay_room_types.create!(
      name: "別施設の客室タイプ",
      room_kind: "private_room"
    )

    get new_tenant_stay_room_path(@listing)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "客室登録"
    assert_select "form[action=?]", tenant_stay_rooms_path(@listing)
    assert_select "input[name='stay_room[name]'][required]"
    assert_select "select[name='stay_room[stay_room_type_id]'] option[value=?]", @room_type.id.to_s,
                  text: @room_type.name
    assert_select "select[name='stay_room[stay_room_type_id]'] option[value=?]", other_room_type.id.to_s,
                  count: 0
  end

  test "客室を施設に登録する" do
    assert_difference "@stay_listing.stay_rooms.count", 1 do
      post tenant_stay_rooms_path(@listing), params: {
        stay_room: {
          name: "101号室",
          stay_room_type_id: @room_type.id,
          active: false,
          notes: "改装予定"
        }
      }
    end

    room = @stay_listing.stay_rooms.order(:id).last
    assert_redirected_to tenant_stay_rooms_path(@listing)
    assert_equal "101号室", room.name
    assert_equal @room_type, room.stay_room_type
    assert_not room.active?
    assert_equal "改装予定", room.notes
  end

  test "客室の入力が不正な場合は登録画面を再表示する" do
    assert_no_difference "StayRoom.count" do
      post tenant_stay_rooms_path(@listing), params: {
        stay_room: { name: "", stay_room_type_id: @room_type.id, active: true }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']"
    assert_select "select[name='stay_room[stay_room_type_id]'] option[selected][value=?]", @room_type.id.to_s
  end

  test "指定した客室タイプの客室だけを一覧表示する" do
    target_room = @stay_listing.stay_rooms.create!(name: "101号室", stay_room_type: @room_type)
    other_room_type = @stay_listing.stay_room_types.create!(name: "和室", room_kind: "private_room")
    other_room = @stay_listing.stay_rooms.create!(name: "和室201", stay_room_type: other_room_type)

    get tenant_stay_rooms_path(@listing, stay_room_type_id: @room_type.id)

    assert_response :success
    assert_includes response.body, target_room.name
    assert_not_includes response.body, other_room.name
  end

  test "客室を更新する" do
    room = @stay_listing.stay_rooms.create!(name: "101号室", stay_room_type: @room_type)

    patch tenant_stay_room_path(@listing, room), params: {
      stay_room: { name: "102号室", stay_room_type_id: "", active: false, notes: "販売停止" }
    }

    assert_redirected_to tenant_stay_rooms_path(@listing)
    room.reload
    assert_equal "102号室", room.name
    assert_nil room.stay_room_type
    assert_not room.active?
    assert_equal "販売停止", room.notes
  end

  test "ベッドがない客室を削除する" do
    room = @stay_listing.stay_rooms.create!(name: "101号室", stay_room_type: @room_type)

    assert_difference "@stay_listing.stay_rooms.count", -1 do
      delete tenant_stay_room_path(@listing, room)
    end

    assert_redirected_to tenant_stay_rooms_path(@listing)
    assert_equal "客室を削除しました", flash[:notice]
  end

  test "ベッドがある客室は削除しない" do
    room = @stay_listing.stay_rooms.create!(name: "101号室", stay_room_type: @room_type)
    room.stay_beds.create!(name: "ベッド1")

    assert_no_difference "StayRoom.count" do
      delete tenant_stay_room_path(@listing, room)
    end

    assert_redirected_to tenant_stay_rooms_path(@listing)
    assert_equal "ベッドが登録されているため客室を削除できません", flash[:alert]
  end

  test "別施設の客室は更新できない" do
    other_listing = @tenant.listings.create!(title: "別ホテル", listing_type: "stay", status: "draft")
    other_stay_listing = StayListing.create!(listing: other_listing)
    other_room = other_stay_listing.stay_rooms.create!(name: "別施設の客室")

    patch tenant_stay_room_path(@listing, other_room), params: {
      stay_room: { name: "不正な更新", active: true }
    }

    assert_response :not_found
    assert_equal "別施設の客室", other_room.reload.name
  end
end
