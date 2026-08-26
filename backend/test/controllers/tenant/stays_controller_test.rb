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

  test "宿泊施設一覧には自テナントの宿泊施設だけを表示する" do
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
          tenant_location_id: @location.id,
          stay_listing: {
            check_in_time: "15:00",
            latest_check_in_time: "21:00",
            check_out_time: "10:00",
            time_zone: "Asia/Tokyo",
            booking_confirmation_mode: "instant",
            approval_deadline_hours: 12,
            booking_open_days_before: 180,
            booking_close_hours_before: 6,
            stay_available_starts_on: "2026-09-01",
            stay_available_ends_on: "2026-12-01",
            house_rules: "館内禁煙"
          }
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
    assert_equal "15:00", listing.stay_listing.check_in_time.strftime("%H:%M")
    assert_equal "21:00", listing.stay_listing.latest_check_in_time.strftime("%H:%M")
    assert_equal "10:00", listing.stay_listing.check_out_time.strftime("%H:%M")
    assert_equal "instant", listing.stay_listing.booking_confirmation_mode
    assert_equal 12, listing.stay_listing.approval_deadline_hours
    assert_equal 180, listing.stay_listing.booking_open_days_before
    assert_equal 6, listing.stay_listing.booking_close_hours_before
    assert_equal Date.new(2026, 9, 1), listing.stay_listing.stay_available_starts_on
    assert_equal Date.new(2026, 12, 1), listing.stay_listing.stay_available_ends_on
    assert_equal "館内禁煙", listing.stay_listing.house_rules
  end

  test "宿泊施設の登録画面と施設別管理画面を専用ルートで表示する" do
    get new_tenant_stay_path

    assert_response :success
    assert_select "h1#tenant-page-title", text: "宿泊施設を登録"
    assert_select "form[action=?]", tenant_stays_path
    assert_select "select[name='listing[tenant_location_id]']"
    assert_select "input[name='listing[title]'][required]"

    listing = create_listing(@tenant, "stay", "詳細施設")
    listing.update!(tenant_location: @location)
    StayListing.create!(listing: listing)
    sign_in @account
    get tenant_stay_path(listing)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "宿泊施設管理"
    assert_select ".stay-facility-navigation__back[href=?]", tenant_stays_path, text: /宿泊施設一覧へ戻る/
    assert_select ".stay-facility-navigation__item.active[href=?]", tenant_stay_path(listing), text: /施設情報/
    assert_select ".stay-facility-navigation__item[href=?]", edit_tenant_stay_path(listing), count: 0
    assert_includes response.body, @location.name
  end

  test "宿泊施設の登録画面に宿泊時刻と予約受付の入力欄を表示する" do
    get new_tenant_stay_path

    assert_response :success
    assert_select "[name='listing[stay_listing][check_in_time]']"
    assert_select "[name='listing[stay_listing][booking_confirmation_mode]']"
    assert_select "[name='listing[stay_listing][house_rules]']"
    assert_select "input[type='hidden'][name='listing[stay_listing][time_zone]'][value='Asia/Tokyo']"
    assert_select "select[name='listing[stay_listing][time_zone]']", count: 0
  end

  test "宿泊施設の編集画面に保存済みの宿泊設定を表示する" do
    listing = create_listing(@tenant, "stay", "設定済み施設")
    StayListing.create!(
      listing: listing,
      booking_confirmation_mode: "instant",
      approval_deadline_hours: 12,
      check_in_time: "15:00",
      latest_check_in_time: "21:00",
      check_out_time: "10:00",
      time_zone: "Asia/Tokyo",
      stay_available_starts_on: Date.new(2026, 9, 1),
      stay_available_ends_on: Date.new(2026, 12, 1),
      booking_open_days_before: 180,
      booking_close_hours_before: 6,
      house_rules: "館内禁煙"
    )

    get edit_tenant_stay_path(listing)

    assert_response :success
    assert_select ".stay-facility-navigation__item.active[href=?]", tenant_stay_path(listing), text: /施設情報/
    assert_select "select[name='listing[stay_listing][booking_confirmation_mode]'] option[value='instant'][selected]", text: "即時予約"
    assert_select "input[name='listing[stay_listing][stay_available_ends_on]'][value='2026-12-01']"
    assert_select "textarea[name='listing[stay_listing][house_rules]']", text: "館内禁煙"
  end

  test "宿泊施設一覧の施設名から詳細画面へ遷移できる" do
    listing = create_listing(@tenant, "stay", "管理対象施設")
    StayListing.create!(listing: listing)

    get tenant_stays_path

    assert_response :success
    assert_select "a[href=?]", tenant_stay_path(listing), text: "管理対象施設"
    assert_select "a[href=?]", tenant_stay_path(listing), text: "詳細"
  end

  test "宿泊施設管理画面に基本情報と宿泊設定を表示する" do
    listing = create_listing(@tenant, "stay", "湖畔ホテル")
    listing.update!(description: "湖を望む宿泊施設です", tenant_location: @location)
    StayListing.create!(
      listing: listing,
      check_in_time: "15:00",
      latest_check_in_time: "21:00",
      check_out_time: "10:00",
      booking_confirmation_mode: "instant",
      approval_deadline_hours: 12,
      booking_open_days_before: 180,
      booking_close_hours_before: 6,
      stay_available_starts_on: Date.new(2026, 9, 1),
      stay_available_ends_on: Date.new(2026, 12, 1),
      house_rules: "館内禁煙"
    )

    get tenant_stay_path(listing)

    assert_response :success
    assert_select "h2", text: "湖畔ホテル"
    assert_includes response.body, "湖を望む宿泊施設です"
    assert_includes response.body, "15:00"
    assert_includes response.body, "即時予約"
    assert_includes response.body, "2026年09月01日"
    assert_includes response.body, "館内禁煙"
    assert_select "a[href=?]", edit_tenant_stay_path(listing), text: "編集"
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
    assert_select "[role='alert']"
  end

  test "宿泊施設を更新できる" do
    listing = create_listing(@tenant, "stay", "更新前")
    StayListing.create!(listing: listing)

    patch tenant_stay_path(listing), params: {
      listing: {
        title: "更新後",
        description: "更新した紹介",
        tenant_location_id: @location.id,
        stay_listing: {
          check_in_time: "16:00",
          latest_check_in_time: "22:00",
          check_out_time: "11:00",
          time_zone: "Asia/Tokyo",
          booking_confirmation_mode: "instant",
          approval_deadline_hours: 24,
          booking_open_days_before: 120,
          booking_close_hours_before: 12,
          stay_available_starts_on: "2026-10-01",
          stay_available_ends_on: "2027-03-01",
          house_rules: "22時以降は静かにしてください"
        }
      }
    }

    assert_redirected_to tenant_stay_path(listing)
    listing.reload
    assert_equal "更新後", listing.title
    assert_equal @location, listing.tenant_location
    assert_equal @member, listing.updated_by_tenant_member
    assert_equal "16:00", listing.stay_listing.check_in_time.strftime("%H:%M")
    assert_equal "instant", listing.stay_listing.booking_confirmation_mode
    assert_equal 120, listing.stay_listing.booking_open_days_before
    assert_equal Date.new(2027, 3, 1), listing.stay_listing.stay_available_ends_on
    assert_equal "22時以降は静かにしてください", listing.stay_listing.house_rules
  end

  test "宿泊設定が不正な場合は宿泊施設と宿泊設定を更新せず入力値を再表示する" do
    listing = create_listing(@tenant, "stay", "更新前")
    stay_listing = StayListing.create!(listing: listing, check_in_time: "15:00", latest_check_in_time: "21:00")

    patch tenant_stay_path(listing), params: {
      listing: {
        title: "保存されない施設名",
        stay_listing: {
          check_in_time: "22:00",
          latest_check_in_time: "20:00",
          time_zone: "Asia/Tokyo"
        }
      }
    }

    assert_response :unprocessable_entity
    assert_equal "更新前", listing.reload.title
    assert_equal "15:00", stay_listing.reload.check_in_time.strftime("%H:%M")
    assert_select "input[name='listing[title]'][value='保存されない施設名']"
    assert_select "input[name='listing[stay_listing][check_in_time]'][value='22:00:00.000']"
    assert_select "[role='alert']"
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
