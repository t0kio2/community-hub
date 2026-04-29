require "test_helper"

class Tenant::ListingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant, @account = create_tenant_account(role: "owner", email: "tenant-listings-owner@example.com")
    @member = @account.tenant_member
    sign_in @account
  end

  test "tenantは自分の掲載一覧を表示できる" do
    own_listing = create_job_listing(title: "自分の求人")
    other_tenant, = create_tenant_account(role: "owner", email: "tenant-listings-other@example.com")
    other_listing = Listing.create!(
      tenant: other_tenant,
      listing_type: "job",
      title: "別テナントの求人",
      status: "draft"
    )

    get tenant_listings_path

    assert_response :success
    assert_includes response.body, own_listing.title
    assert_not_includes response.body, other_listing.title
  end

  test "求人掲載作成画面を表示できる" do
    get new_tenant_listing_path(listing_type: "job")

    assert_response :success
    assert_includes response.body, "掲載作成"
    assert_includes response.body, "勤務エリア"
  end

  test "宿泊掲載作成画面を表示できる" do
    get new_tenant_listing_path(listing_type: "stay")

    assert_response :success
    assert_includes response.body, "掲載作成"
    assert_includes response.body, "チェックイン"
  end

  test "求人掲載を作成できる" do
    assert_difference("Listing.count", 1) do
      assert_difference("JobListing.count", 1) do
        post tenant_listings_path, params: {
          listing: {
            listing_type: "job",
            title: "新しい求人",
            description: "求人説明",
            status: "published",
            job_listing: {
              employment_type: "part_time",
              job_category: "接客",
              work_area: "東京都",
              work_address: "東京都千代田区",
              salary_type: "hourly",
              salary_min: 1200,
              salary_max: 1800,
              working_hours: "10:00-18:00",
              work_days: "週3日",
              application_limit: 5
            }
          }
        }
      end
    end

    listing = Listing.order(:created_at).last
    assert_redirected_to tenant_listing_path(listing)
    assert_equal @tenant, listing.tenant
    assert_equal @member, listing.created_by_tenant_member
    assert_equal "published", listing.status
    assert_not_nil listing.published_at
    assert_equal "東京都", listing.job_listing.work_area
  end

  test "宿泊掲載を作成できる" do
    assert_difference("Listing.count", 1) do
      assert_difference("StayListing.count", 1) do
        post tenant_listings_path, params: {
          listing: {
            listing_type: "stay",
            title: "新しい宿泊",
            description: "宿泊説明",
            status: "draft",
            stay_listing: {
              stay_type: "private_room",
              address: "京都府京都市",
              capacity: 2,
              price_per_night: 8000,
              check_in_time: "15:00",
              check_out_time: "10:00",
              available_from: "2026-05-01",
              available_until: "2026-05-31"
            }
          }
        }
      end
    end

    listing = Listing.order(:created_at).last
    assert_redirected_to tenant_listing_path(listing)
    assert_equal "stay", listing.listing_type
    assert_equal 2, listing.stay_listing.capacity
  end

  test "掲載を更新できる" do
    listing = create_job_listing(title: "更新前")

    patch tenant_listing_path(listing), params: {
      listing: {
        listing_type: "stay",
        title: "更新後",
        description: "更新説明",
        status: "closed",
        job_listing: {
          employment_type: "contract",
          work_area: "大阪府",
          salary_type: "monthly",
          salary_min: 200000,
          salary_max: 250000
        }
      }
    }

    assert_redirected_to tenant_listing_path(listing)
    listing.reload
    assert_equal "job", listing.listing_type
    assert_equal "更新後", listing.title
    assert_equal "closed", listing.status
    assert_not_nil listing.closed_at
    assert_equal @member, listing.updated_by_tenant_member
    assert_equal "大阪府", listing.job_listing.work_area
  end

  test "他tenantの掲載は編集できない" do
    other_tenant, = create_tenant_account(role: "owner", email: "tenant-listings-edit-other@example.com")
    listing = Listing.create!(
      tenant: other_tenant,
      listing_type: "job",
      title: "別テナントの求人",
      status: "draft"
    )

    assert_raises(ActiveRecord::RecordNotFound) do
      get edit_tenant_listing_path(listing)
    end
  end

  private

  def create_tenant_account(role:, email:)
    tenant = Tenant.create!(
      name: "Sample Lodge",
      kana: "サンプルロッジ",
      address: "Tokyo",
      status: "active"
    )
    account = TenantAccount.create!(
      email: email,
      password: "password",
      password_confirmation: "password"
    )
    TenantMember.create!(
      tenant: tenant,
      account: account,
      role: role,
      status: "active"
    )

    [tenant, account]
  end

  def create_job_listing(title:)
    listing = Listing.create!(
      tenant: @tenant,
      created_by_tenant_member: @member,
      updated_by_tenant_member: @member,
      listing_type: "job",
      title: title,
      status: "draft"
    )
    JobListing.create!(listing: listing, work_area: "東京都")
    listing
  end
end
