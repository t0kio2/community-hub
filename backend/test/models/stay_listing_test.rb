require "test_helper"

class StayListingTest < ActiveSupport::TestCase
  test "有効な宿泊詳細を保存できる" do
    listing = Listing.create!(
      tenant: tenants(:one),
      listing_type: "stay",
      title: "追加宿泊",
      status: "draft"
    )
    stay_listing = StayListing.new(listing: listing)

    assert stay_listing.valid?
  end

  test "宿泊以外の掲載には紐づけられない" do
    stay_listing = StayListing.new(listing: listings(:job))

    assert_not stay_listing.valid?
    assert_includes stay_listing.errors[:listing], "は宿泊である必要があります"
  end

  test "宿泊可能期間の終了日は開始日より後にする" do
    stay_listing = stay_listings(:one)
    stay_listing.stay_available_starts_on = Date.new(2026, 6, 1)
    stay_listing.stay_available_ends_on = Date.new(2026, 6, 1)

    assert_not stay_listing.valid?
    assert_includes stay_listing.errors[:stay_available_ends_on], "は宿泊可能期間の開始日より後にしてください"
  end

  test "最終チェックイン時刻はチェックイン開始時刻より後にする" do
    stay_listing = stay_listings(:one)
    stay_listing.latest_check_in_time = stay_listing.check_in_time

    assert_not stay_listing.valid?
    assert_includes stay_listing.errors[:latest_check_in_time], "はチェックイン開始時刻より後にしてください"
  end

  test "予約受付期間は正の時間幅にする" do
    stay_listing = stay_listings(:one)
    stay_listing.booking_open_days_before = 1
    stay_listing.booking_close_hours_before = 24

    assert_not stay_listing.valid?
    assert_includes stay_listing.errors[:booking_close_hours_before], "は予約受付開始より前に受付が終了する値にしてください"
  end

  test "予約設定は許可された範囲内にする" do
    stay_listing = stay_listings(:one)
    stay_listing.booking_confirmation_mode = "automatic"
    stay_listing.approval_deadline_hours = 73
    stay_listing.booking_open_days_before = 0
    stay_listing.booking_close_hours_before = 721

    assert_not stay_listing.valid?
    assert stay_listing.errors.of_kind?(:booking_confirmation_mode, :inclusion)
    assert stay_listing.errors.of_kind?(:approval_deadline_hours, :less_than_or_equal_to)
    assert stay_listing.errors.of_kind?(:booking_open_days_before, :greater_than_or_equal_to)
    assert stay_listing.errors.of_kind?(:booking_close_hours_before, :less_than_or_equal_to)
  end

  test "IANAタイムゾーンだけを設定できる" do
    stay_listing = stay_listings(:one)
    stay_listing.time_zone = "Tokyo"

    assert_not stay_listing.valid?
    assert_includes stay_listing.errors[:time_zone], "は有効なIANAタイムゾーンにしてください"
  end

  test "ERで定義したカラムだけを宿泊詳細に保持する" do
    assert_includes StayListing.column_names, "latest_check_in_time"
    assert_not_includes StayListing.column_names, "stay_type"
    assert_not_includes StayListing.column_names, "address"
    assert_not_includes StayListing.column_names, "capacity"
    assert_not_includes StayListing.column_names, "price_per_night"
    assert_not_includes StayListing.column_names, "available_from"
    assert_not_includes StayListing.column_names, "available_until"
    assert_not_includes StayListing.column_names, "amenities"
  end
end
