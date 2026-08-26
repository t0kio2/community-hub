require "test_helper"

class StayBedBlockTest < ActiveSupport::TestCase
  setup do
    tenant = Tenant.create!(name: "ベッドブロックテナント", kana: "ベッドブロックテナント", status: "active")
    listing = tenant.listings.create!(title: "テストホテル", listing_type: "stay", status: "draft")
    @stay_listing = StayListing.create!(listing: listing)
  end

  test "相部屋に所属するベッドへブロックを登録できる" do
    room_type = @stay_listing.stay_room_types.create!(name: "ドミトリー", room_kind: "shared_room", capacity: 1)
    room = @stay_listing.stay_rooms.create!(name: "相部屋A", stay_room_type: room_type)
    bed = room.stay_beds.create!(name: "ベッド1")
    block = bed.stay_bed_blocks.new(
      starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 2), reason: "cleaning"
    )

    assert_predicate block, :valid?
  end

  test "個室に所属するベッドへブロックを登録できない" do
    room_type = @stay_listing.stay_room_types.create!(name: "個室", room_kind: "private_room", capacity: 2)
    room = @stay_listing.stay_rooms.create!(name: "101号室", stay_room_type: room_type)
    bed = room.stay_beds.create!(name: "不正なベッド")
    block = bed.stay_bed_blocks.new(
      starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 2), reason: "cleaning"
    )

    assert_not block.valid?
    assert block.errors.added?(:stay_bed, "は相部屋に所属するベッドを選択してください")
  end
end
