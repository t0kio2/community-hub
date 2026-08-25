require "test_helper"

class StayRatePlanTest < ActiveSupport::TestCase
  setup do
    tenant = Tenant.create!(name: "料金モデルテナント", kana: "リョウキンモデルテナント", status: "active")
    listing = tenant.listings.create!(title: "料金モデルホテル", listing_type: "stay", status: "draft")
    @stay_listing = StayListing.create!(listing: listing)
  end

  test "料金プラン名は施設内で一意にする" do
    @stay_listing.stay_rate_plans.create!(name: "素泊まり")
    duplicate = @stay_listing.stay_rate_plans.new(name: "素泊まり")

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:name, :taken)
  end

  test "許可されていない販売条件は代入時に拒否する" do
    rate_plan = @stay_listing.stay_rate_plans.new(name: "不正プラン")

    assert_raises(ArgumentError) { rate_plan.meal_type = "invalid" }
    assert_raises(ArgumentError) { rate_plan.cancellation_policy_type = "invalid" }
    assert_raises(ArgumentError) { rate_plan.status = "invalid" }
  end

  test "下書きまたは停止中で基本料金がない場合だけ削除可能にする" do
    draft = @stay_listing.stay_rate_plans.create!(name: "下書き", status: "draft")
    inactive = @stay_listing.stay_rate_plans.create!(name: "停止中", status: "inactive")
    published = @stay_listing.stay_rate_plans.create!(name: "公開中", status: "published")

    assert_predicate draft, :destroyable?
    assert_predicate inactive, :destroyable?
    assert_not_predicate published, :destroyable?
  end
end
