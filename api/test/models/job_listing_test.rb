require "test_helper"

class JobListingTest < ActiveSupport::TestCase
  test "有効な求人詳細を保存できる" do
    listing = Listing.create!(
      tenant: tenants(:one),
      listing_type: "job",
      title: "追加求人",
      status: "draft"
    )
    job_listing = JobListing.new(
      listing: listing,
      employment_type: "part_time",
      work_area: "東京都",
      salary_type: "hourly",
      salary_min: 1000,
      salary_max: 1500,
      application_limit: 3
    )

    assert job_listing.valid?
  end

  test "求人以外の掲載には紐づけられない" do
    job_listing = JobListing.new(listing: listings(:stay))

    assert_not job_listing.valid?
    assert_includes job_listing.errors[:listing], "は求人である必要があります"
  end

  test "給与上限は給与下限以上にする" do
    job_listing = job_listings(:one)
    job_listing.salary_min = 2000
    job_listing.salary_max = 1000

    assert_not job_listing.valid?
    assert_includes job_listing.errors[:salary_max], "は最低給与以上にしてください"
  end

  test "同じ掲載に求人詳細を重複作成できない" do
    job_listing = JobListing.new(listing: listings(:job))

    assert_not job_listing.valid?
    assert job_listing.errors.of_kind?(:listing_id, :taken)
  end
end
