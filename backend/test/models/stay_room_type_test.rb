require "test_helper"

class StayRoomTypeTest < ActiveSupport::TestCase
  setup do
    tenant = Tenant.create!(name: "宿泊テナント", kana: "シュクハクテナント", status: "active")
    listing = tenant.listings.create!(title: "テストホテル", listing_type: "stay", status: "draft")
    @stay_listing = StayListing.create!(listing: listing)
  end

  test "名称と利用形態があれば登録できる" do
    room_type = @stay_listing.stay_room_types.new(
      name: "スタンダードツイン",
      room_kind: "private_room",
      capacity: 2
    )

    assert_predicate room_type, :valid?
  end

  test "利用形態と状態を文字列として保存する" do
    room_type = @stay_listing.stay_room_types.create!(
      name: "文字列enum確認",
      room_kind: "private_room",
      status: "published"
    )

    assert_equal "private_room", room_type.reload.room_kind
    assert_equal "published", room_type.status
  end

  test "名称と利用形態は必須" do
    room_type = @stay_listing.stay_room_types.new(name: "", room_kind: "")

    assert_not room_type.valid?
    assert_predicate room_type.errors[:name], :any?
    assert_predicate room_type.errors[:room_kind], :any?
  end

  test "定員は入力する場合1以上の整数にする" do
    room_type = @stay_listing.stay_room_types.new(
      name: "不正な定員",
      room_kind: "private_room",
      capacity: 0
    )

    assert_not room_type.valid?
    assert_predicate room_type.errors[:capacity], :any?
  end

  test "同じ施設に同名の客室タイプは登録できない" do
    @stay_listing.stay_room_types.create!(name: "ツイン", room_kind: "private_room")
    duplicate = @stay_listing.stay_room_types.new(name: "ツイン", room_kind: "private_room")

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:name], :any?
  end

  test "別施設には同名の客室タイプを登録できる" do
    other_listing = @stay_listing.listing.tenant.listings.create!(
      title: "別ホテル",
      listing_type: "stay",
      status: "draft"
    )
    other_stay_listing = StayListing.create!(listing: other_listing)
    @stay_listing.stay_room_types.create!(name: "ツイン", room_kind: "private_room")
    room_type = other_stay_listing.stay_room_types.new(name: "ツイン", room_kind: "private_room")

    assert_predicate room_type, :valid?
  end

  test "相部屋の定員は1にする" do
    room_type = @stay_listing.stay_room_types.new(
      name: "ドミトリー",
      room_kind: "shared_room",
      capacity: 2
    )

    assert_not room_type.valid?
    assert_predicate room_type.errors[:capacity], :any?
  end
end
