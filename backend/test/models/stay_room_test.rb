require "test_helper"

class StayRoomTest < ActiveSupport::TestCase
  setup do
    tenant = Tenant.create!(name: "宿泊テナント", kana: "シュクハクテナント", status: "active")
    listing = tenant.listings.create!(title: "テストホテル", listing_type: "stay", status: "draft")
    other_listing = tenant.listings.create!(title: "別ホテル", listing_type: "stay", status: "draft")
    @stay_listing = StayListing.create!(listing: listing)
    @other_stay_listing = StayListing.create!(listing: other_listing)
    @room_type = @stay_listing.stay_room_types.create!(name: "ツイン", room_kind: "private_room")
    @other_room_type = @other_stay_listing.stay_room_types.create!(name: "別施設のツイン", room_kind: "private_room")
  end

  test "同じ施設の客室タイプを割り当てられる" do
    room = @stay_listing.stay_rooms.new(name: "101号室", stay_room_type: @room_type)

    assert_predicate room, :valid?
  end

  test "客室タイプを未割当てにできる" do
    room = @stay_listing.stay_rooms.new(name: "未分類客室", stay_room_type: nil)

    assert_predicate room, :valid?
  end

  test "別施設の客室タイプは割り当てられない" do
    room = @stay_listing.stay_rooms.new(name: "不正な客室", stay_room_type: @other_room_type)

    assert_not room.valid?
    assert_predicate room.errors[:stay_room_type], :any?
  end

  test "客室名は必須" do
    room = @stay_listing.stay_rooms.new(name: "", stay_room_type: @room_type)

    assert_not room.valid?
    assert_predicate room.errors[:name], :any?
  end

  test "同じ施設に同名の客室は登録できない" do
    @stay_listing.stay_rooms.create!(name: "101号室", stay_room_type: @room_type)
    duplicate = @stay_listing.stay_rooms.new(name: "101号室", stay_room_type: @room_type)

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:name], :any?
  end

  test "別施設には同名の客室を登録できる" do
    @stay_listing.stay_rooms.create!(name: "101号室", stay_room_type: @room_type)
    room = @other_stay_listing.stay_rooms.new(name: "101号室", stay_room_type: @other_room_type)

    assert_predicate room, :valid?
  end

  test "ベッドがある客室は削除できない" do
    room = @stay_listing.stay_rooms.create!(name: "101号室", stay_room_type: @room_type)
    room.stay_beds.create!(name: "ベッド1")

    assert_not room.destroy
    assert_predicate room.errors[:base], :any?
    assert_predicate StayRoom, :exists?, room.id
  end
end
