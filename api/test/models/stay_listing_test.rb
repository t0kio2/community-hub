require "test_helper"

class StayListingTest < ActiveSupport::TestCase
  test "有効な宿泊詳細を保存できる" do
    listing = Listing.create!(
      tenant: tenants(:one),
      listing_type: "stay",
      title: "追加宿泊",
      status: "draft"
    )
    stay_listing = StayListing.new(
      listing: listing,
      stay_type: "private_room",
      capacity: 2,
      price_per_night: 8000,
      available_from: Date.new(2026, 5, 1),
      available_until: Date.new(2026, 5, 31)
    )

    assert stay_listing.valid?
  end

  test "宿泊以外の掲載には紐づけられない" do
    stay_listing = StayListing.new(listing: listings(:job))

    assert_not stay_listing.valid?
    assert_includes stay_listing.errors[:listing], "は宿泊である必要があります"
  end

  test "予約可能終了日は開始日以降にする" do
    stay_listing = stay_listings(:one)
    stay_listing.available_from = Date.new(2026, 6, 1)
    stay_listing.available_until = Date.new(2026, 5, 31)

    assert_not stay_listing.valid?
    assert_includes stay_listing.errors[:available_until], "は開始日以降にしてください"
  end

  test "定員は1以上にする" do
    stay_listing = stay_listings(:one)
    stay_listing.capacity = 0

    assert_not stay_listing.valid?
    assert stay_listing.errors.of_kind?(:capacity, :greater_than)
  end
end
