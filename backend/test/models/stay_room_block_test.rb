require "test_helper"

class StayRoomBlockTest < ActiveSupport::TestCase
  setup do
    tenant = Tenant.create!(name: "ブロックテナント", kana: "ブロックテナント", status: "active")
    listing = tenant.listings.create!(title: "テストホテル", listing_type: "stay", status: "draft")
    stay_listing = StayListing.create!(listing: listing)
    @room = stay_listing.stay_rooms.create!(name: "101号室")
  end

  test "停止する最初の宿泊日より後の利用再開日を登録できる" do
    block = @room.stay_room_blocks.new(
      starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 3), reason: "maintenance"
    )

    assert_predicate block, :valid?
  end

  test "利用再開日が開始日以前の場合は登録できない" do
    block = @room.stay_room_blocks.new(
      starts_on: Date.new(2026, 9, 3), ends_on: Date.new(2026, 9, 3), reason: "maintenance"
    )

    assert_not block.valid?
    assert block.errors.added?(:ends_on, "は停止する最初の宿泊日より後にしてください")
  end

  test "定義されていない停止理由は登録できない" do
    block = @room.stay_room_blocks.new(
      starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 3), reason: "unknown"
    )

    assert_not block.valid?
    assert block.errors.added?(:reason, :inclusion, value: "unknown")
  end
end
