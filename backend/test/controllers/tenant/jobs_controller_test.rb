require "test_helper"

class Tenant::JobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant, @account = create_tenant_account("tenant-jobs@example.com")
    @member = @account.tenant_member
    sign_in @account
  end

  test "求人一覧には自テナントの求人だけを表示する" do
    job = create_listing(@tenant, "job", "表示する求人")
    stay = create_listing(@tenant, "stay", "表示しない宿泊施設")
    other_tenant, = create_tenant_account("tenant-jobs-other@example.com")
    other_job = create_listing(other_tenant, "job", "他テナントの求人")

    get tenant_jobs_path

    assert_response :success
    assert_includes response.body, job.title
    assert_not_includes response.body, stay.title
    assert_not_includes response.body, other_job.title
    assert_select ".tenant-menu-items a.active[href=?]", tenant_jobs_path
  end

  test "求人と求人詳細を同じトランザクションで作成する" do
    assert_difference([ "Listing.count", "JobListing.count" ], 1) do
      post tenant_jobs_path, params: {
        listing: {
          title: "新しい求人",
          description: "求人の説明",
          status: "published",
          job_listing: { employment_type: "part_time", work_area: "東京都" }
        }
      }
    end

    listing = @tenant.listings.order(:id).last
    assert_redirected_to tenant_job_path(listing)
    assert_equal "job", listing.listing_type
    assert_equal @member, listing.created_by_tenant_member
    assert_equal "東京都", listing.job_listing.work_area
    assert_not_nil listing.published_at
  end

  test "求人の作成画面と詳細画面を専用ルートで表示する" do
    get new_tenant_job_path

    assert_response :success
    assert_select "h1#tenant-page-title", text: "求人を作成"
    assert_select "form.authentication-form", count: 0
    assert_select "form.listing-form[action=?]", tenant_jobs_path
    assert_select ".type-switch", count: 0

    listing = create_listing(@tenant, "job", "詳細求人")
    JobListing.create!(listing: listing, work_area: "北海道")
    sign_in @account
    get tenant_job_path(listing)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "求人詳細"
    assert_select "a[href=?]", edit_tenant_job_path(listing), text: "編集"
    assert_includes response.body, "北海道"
  end

  test "求人の入力エラーではどちらのレコードも作成しない" do
    assert_no_difference([ "Listing.count", "JobListing.count" ]) do
      post tenant_jobs_path, params: {
        listing: { title: "", status: "draft", job_listing: { employment_type: "part_time" } }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors", count: 1
  end

  test "求人を更新できる" do
    listing = create_listing(@tenant, "job", "更新前")
    JobListing.create!(listing: listing, work_area: "東京")

    patch tenant_job_path(listing), params: {
      listing: { title: "更新後", status: "closed", job_listing: { work_area: "大阪" } }
    }

    assert_redirected_to tenant_job_path(listing)
    assert_equal "更新後", listing.reload.title
    assert_equal "大阪", listing.job_listing.reload.work_area
    assert_not_nil listing.closed_at
  end

  test "宿泊Listingは求人URLで取得できない" do
    stay = create_listing(@tenant, "stay", "宿泊施設")

    get tenant_job_path(stay)

    assert_response :not_found
  end

  private

  def create_tenant_account(email)
    tenant = Tenant.create!(name: "求人テナント", kana: "キュウジンテナント", status: "active")
    account = TenantAccount.create!(email: email, password: "password", password_confirmation: "password")
    TenantMember.create!(tenant: tenant, account: account, role: "owner", status: "active")
    [ tenant, account ]
  end

  def create_listing(tenant, type, title)
    tenant.listings.create!(listing_type: type, title: title, status: "draft")
  end
end
