require "test_helper"

class Tenant::StayManagement::InventoryBlocksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(name: "ブロック管理テナント", kana: "ブロックカンリテナント", status: "active")
    @account = TenantAccount.create!(
      email: "inventory-blocks@example.com", password: "password", password_confirmation: "password"
    )
    TenantMember.create!(tenant: @tenant, account: @account, role: "owner", status: "active")
    @listing = @tenant.listings.create!(title: "テストホテル", listing_type: "stay", status: "draft")
    @stay_listing = StayListing.create!(listing: @listing)
    @room_type = @stay_listing.stay_room_types.create!(
      name: "ドミトリー", room_kind: "shared_room", capacity: 1
    )
    @room = @stay_listing.stay_rooms.create!(name: "相部屋A", stay_room_type: @room_type)
    @bed = @room.stay_beds.create!(name: "ベッド1")
    sign_in @account
  end

  test "客室ブロックを登録して一覧に表示する" do
    assert_difference "StayRoomBlock.count", 1 do
      post tenant_stay_room_room_blocks_path(@listing, @room), params: {
        stay_room_block: {
          starts_on: "2026-09-01", ends_on: "2026-09-03", reason: "maintenance", notes: "空調修理"
        }
      }
    end

    block = @room.stay_room_blocks.last
    assert_redirected_to tenant_stay_room_room_blocks_path(@listing, @room)
    assert_equal Date.new(2026, 9, 1), block.starts_on
    assert_equal "空調修理", block.notes

    sign_in @account
    get tenant_stay_room_room_blocks_path(@listing, @room)
    assert_response :success
    assert_includes response.body, "メンテナンス"
    assert_includes response.body, "空調修理"
  end

  test "不正な期間では客室ブロックを登録せず入力画面を再表示する" do
    assert_no_difference "StayRoomBlock.count" do
      post tenant_stay_room_room_blocks_path(@listing, @room), params: {
        stay_room_block: { starts_on: "2026-09-03", ends_on: "2026-09-01", reason: "cleaning" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']"
    assert_select "input[name='stay_room_block[starts_on]'][value='2026-09-03']"
  end

  test "客室ブロックを更新して解除する" do
    block = @room.stay_room_blocks.create!(
      starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 2), reason: "cleaning"
    )

    patch tenant_stay_room_room_block_path(@listing, @room, block), params: {
      stay_room_block: { starts_on: "2026-09-02", ends_on: "2026-09-04", reason: "operator_block", notes: "貸切対応" }
    }

    assert_redirected_to tenant_stay_room_room_blocks_path(@listing, @room)
    assert_equal "operator_block", block.reload.reason
    assert_equal "貸切対応", block.notes

    sign_in @account
    assert_difference "StayRoomBlock.count", -1 do
      delete tenant_stay_room_room_block_path(@listing, @room, block)
    end
    assert_equal "客室ブロックを解除しました", flash[:notice]
  end

  test "ベッドブロックを登録して解除する" do
    assert_difference "StayBedBlock.count", 1 do
      post tenant_stay_room_bed_bed_blocks_path(@listing, @room, @bed), params: {
        stay_bed_block: { starts_on: "2026-10-01", ends_on: "2026-10-02", reason: "other", notes: "点検" }
      }
    end

    block = @bed.stay_bed_blocks.last
    assert_redirected_to tenant_stay_room_bed_bed_blocks_path(@listing, @room, @bed)
    assert_equal "点検", block.notes

    sign_in @account
    assert_difference "StayBedBlock.count", -1 do
      delete tenant_stay_room_bed_bed_block_path(@listing, @room, @bed, block)
    end
    assert_equal "ベッドブロックを解除しました", flash[:notice]
  end

  test "施設内の客室ブロックとベッドブロックをまとめて表示する" do
    @room.stay_room_blocks.create!(
      starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 2), reason: "maintenance", notes: "客室修理"
    )
    @bed.stay_bed_blocks.create!(
      starts_on: Date.new(2026, 9, 3), ends_on: Date.new(2026, 9, 4), reason: "cleaning", notes: "ベッド清掃"
    )

    get tenant_stay_inventory_blocks_path(@listing)

    assert_response :success
    assert_includes response.body, "相部屋A"
    assert_includes response.body, "相部屋A / ベッド1"
    assert_includes response.body, "客室修理"
    assert_includes response.body, "ベッド清掃"
  end

  test "別施設の客室とベッドのブロックを操作できない" do
    other_listing = @tenant.listings.create!(title: "別ホテル", listing_type: "stay", status: "draft")
    other_stay_listing = StayListing.create!(listing: other_listing)
    other_room = other_stay_listing.stay_rooms.create!(name: "別施設の客室")

    assert_no_difference "StayRoomBlock.count" do
      post tenant_stay_room_room_blocks_path(@listing, other_room), params: {
        stay_room_block: { starts_on: "2026-09-01", ends_on: "2026-09-02", reason: "maintenance" }
      }
    end
    assert_response :not_found

    sign_in @account
    get tenant_stay_room_bed_bed_blocks_path(@listing, @room, StayBed.create!(stay_room: other_room, name: "別施設ベッド"))
    assert_response :not_found
  end
end
