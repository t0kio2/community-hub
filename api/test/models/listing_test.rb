require "test_helper"

class ListingTest < ActiveSupport::TestCase
  test "有効な求人掲載を保存できる" do
    listing = Listing.new(
      tenant: tenants(:one),
      created_by_tenant_member: tenant_members(:one),
      updated_by_tenant_member: tenant_members(:one),
      listing_type: "job",
      title: "新しい求人",
      status: "draft"
    )

    assert listing.valid?
  end

  test "掲載種別は定義済みの値だけを許可する" do
    listing = listings(:job)
    listing.listing_type = "event"

    assert_not listing.valid?
    assert listing.errors.of_kind?(:listing_type, :inclusion)
  end

  test "ステータスは定義済みの値だけを許可する" do
    listing = listings(:job)
    listing.status = "unknown"

    assert_not listing.valid?
    assert listing.errors.of_kind?(:status, :inclusion)
  end

  test "タイトルは必須" do
    listing = listings(:job)
    listing.title = nil

    assert_not listing.valid?
    assert listing.errors.of_kind?(:title, :blank)
  end
end
