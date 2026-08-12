require "test_helper"

class Tenant::StaysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant, @account = create_tenant_account("tenant-stays@example.com")
    @member = @account.tenant_member
    @location = @tenant.tenant_locations.create!(
      name: "本館", location_type: "facility", latitude: 35.68, longitude: 139.76
    )
    sign_in @account
  end

  test "宿泊一覧には自テナントの宿泊施設だけを表示する" do
    stay = create_listing(@tenant, "stay", "表示する宿泊施設")
    job = create_listing(@tenant, "job", "表示しない求人")
    other_tenant, = create_tenant_account("tenant-stays-other@example.com")
    other_stay = create_listing(other_tenant, "stay", "他テナントの宿泊施設")

    get tenant_stays_path

    assert_response :success
    assert_includes response.body, stay.title
    assert_not_includes response.body, job.title
    assert_not_includes response.body, other_stay.title
    assert_select ".tenant-menu-items a.active[href=?]", tenant_stays_path
  end

  test "宿泊施設と宿泊詳細を同じトランザクションで登録する" do
    assert_difference([ "Listing.count", "StayListing.count" ], 1) do
      post tenant_stays_path, params: {
        listing: {
          title: "新しい宿泊施設",
          description: "施設紹介",
          tenant_location_id: @location.id
        }
      }
    end

    listing = @tenant.listings.order(:id).last
    assert_redirected_to tenant_stay_path(listing)
    assert_equal "stay", listing.listing_type
    assert_equal "draft", listing.status
    assert_equal @location, listing.tenant_location
    assert_equal @member, listing.created_by_tenant_member
    assert_predicate listing.stay_listing, :persisted?
  end

  test "宿泊施設の登録画面と詳細画面を専用ルートで表示する" do
    get new_tenant_stay_path

    assert_response :success
    assert_select "h1#tenant-page-title", text: "宿泊施設を登録"
    assert_select "form.listing-form[action=?]", tenant_stays_path
    assert_select "select[name='listing[tenant_location_id]']", count: 1

    listing = create_listing(@tenant, "stay", "詳細施設")
    listing.update!(tenant_location: @location)
    StayListing.create!(listing: listing)
    sign_in @account
    get tenant_stay_path(listing)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "宿泊施設詳細"
    assert_select "a[href=?]", edit_tenant_stay_path(listing), text: "編集"
    assert_includes response.body, @location.name
  end

  test "別テナントの拠点では宿泊施設を登録しない" do
    other_tenant, = create_tenant_account("tenant-stays-location-other@example.com")
    other_location = other_tenant.tenant_locations.create!(
      name: "別拠点", location_type: "facility", latitude: 34.69, longitude: 135.50
    )

    assert_no_difference([ "Listing.count", "StayListing.count" ]) do
      post tenant_stays_path, params: {
        listing: { title: "不正な施設", tenant_location_id: other_location.id }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors", count: 1
  end

  test "宿泊施設を更新できる" do
    listing = create_listing(@tenant, "stay", "更新前")
    StayListing.create!(listing: listing)

    patch tenant_stay_path(listing), params: {
      listing: { title: "更新後", description: "更新した紹介", tenant_location_id: @location.id }
    }

    assert_redirected_to tenant_stay_path(listing)
    listing.reload
    assert_equal "更新後", listing.title
    assert_equal @location, listing.tenant_location
    assert_equal @member, listing.updated_by_tenant_member
  end

  test "求人Listingは宿泊URLで取得できない" do
    job = create_listing(@tenant, "job", "求人")

    get tenant_stay_path(job)

    assert_response :not_found
  end

  private

  def create_tenant_account(email)
    tenant = Tenant.create!(name: "宿泊テナント", kana: "シュクハクテナント", status: "active")
    account = TenantAccount.create!(email: email, password: "password", password_confirmation: "password")
    TenantMember.create!(tenant: tenant, account: account, role: "owner", status: "active")
    [ tenant, account ]
  end

  def create_listing(tenant, type, title)
    tenant.listings.create!(listing_type: type, title: title, status: "draft")
  end
end
