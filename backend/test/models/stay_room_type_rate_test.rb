require "test_helper"

class StayRoomTypeRateTest < ActiveSupport::TestCase
  setup do
    tenant = Tenant.create!(name: "基本料金テナント", kana: "キホンリョウキンテナント", status: "active")
    listing = tenant.listings.create!(title: "基本料金ホテル", listing_type: "stay", status: "draft")
    @stay_listing = StayListing.create!(listing: listing)
    @room_type = @stay_listing.stay_room_types.create!(name: "ツイン", room_kind: "private_room", capacity: 2)
    @rate_plan = @stay_listing.stay_rate_plans.create!(name: "素泊まり")
  end

  test "基本料金は1円以上の整数にする" do
    room_type_rate = StayRoomTypeRate.new(
      stay_room_type: @room_type,
      stay_rate_plan: @rate_plan,
      price_per_night_amount: 0
    )

    assert_not room_type_rate.valid?
    assert room_type_rate.errors.of_kind?(:price_per_night_amount, :greater_than)
  end

  test "Room Typeと料金プランは同じ施設に属する" do
    other_listing = @stay_listing.listing.tenant.listings.create!(
      title: "別ホテル",
      listing_type: "stay",
      status: "draft"
    )
    other_stay_listing = StayListing.create!(listing: other_listing)
    other_room_type = other_stay_listing.stay_room_types.create!(
      name: "別施設ツイン",
      room_kind: "private_room",
      capacity: 2
    )
    room_type_rate = StayRoomTypeRate.new(
      stay_room_type: other_room_type,
      stay_rate_plan: @rate_plan,
      price_per_night_amount: 10_000
    )

    assert_not room_type_rate.valid?
    assert_predicate room_type_rate.errors[:stay_room_type], :any?
  end
end
