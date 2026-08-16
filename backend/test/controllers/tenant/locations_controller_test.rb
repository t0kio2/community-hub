require "test_helper"

class Tenant::LocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant, @account = create_tenant_account(role: "owner", email: "tenant-locations-owner@example.com")
    sign_in @account
  end

  test "ownerは自テナントの拠点一覧を表示できる" do
    own_location = create_location(@tenant, name: "自社拠点")
    other_tenant, = create_tenant_account(role: "owner", email: "tenant-locations-other@example.com")
    other_location = create_location(other_tenant, name: "他社拠点")

    get tenant_locations_path

    assert_response :success
    assert_select "h1#tenant-page-title", text: "拠点管理"
    assert_select ".tenant-menu-items a.active[href=?]", tenant_locations_path
    assert_select "dialog[data-confirmation-modal]", count: 1
    assert_select "a.tenant-location-edit-button[href=?]", edit_tenant_location_path(own_location), count: 1
    assert_select "button.tenant-location-delete-button", text: "削除", count: 1
    assert_select 'form[data-confirm-message][action=?]', tenant_location_path(own_location), count: 1
    assert_not_includes response.body, "turbo-confirm"
    assert_includes response.body, own_location.name
    assert_not_includes response.body, other_location.name
  end

  test "ownerは拠点を代表拠点として登録できる" do
    assert_difference -> { TenantLocation.count }, 1 do
      post tenant_locations_path, params: {
        tenant_location: valid_location_params(name: "新しい本社"),
        primary_location: "1"
      }
    end

    location = TenantLocation.find_by!(name: "新しい本社")
    assert_redirected_to tenant_locations_path
    assert_equal @tenant, location.tenant
    assert_equal location, @tenant.reload.primary_tenant_location
  end

  test "APIキー未設定の場合は拠点登録画面に設定案内を表示する" do
    with_google_maps_api_key(nil) do
      get new_tenant_location_path

      assert_response :success
      assert_select "[data-google-maps-preview]", count: 1
      assert_select ".tenant-location-form__actions a", count: 0
      assert_select "[data-map-frame]", count: 0
      assert_includes response.body, "GOOGLE_MAPS_EMBED_API_KEY"
    end
  end

  test "APIキー設定済みの拠点編集画面に地図を表示する" do
    location = create_location(@tenant, name: "地図表示拠点")

    with_google_maps_api_key("test-embed-key") do
      get edit_tenant_location_path(location)

      assert_response :success
      assert_select 'iframe[data-map-frame][src*="maps/embed/v1/view"]', count: 1
      assert_select ".tenant-location-form__actions a", count: 0
      assert_select 'iframe[src*="center=35.681236"]', count: 1
      assert_select 'a[data-map-external-link][target="_blank"]', count: 1
    end
  end

  test "入力が不正な場合は拠点を登録しない" do
    assert_no_difference -> { TenantLocation.count } do
      post tenant_locations_path, params: {
        tenant_location: valid_location_params(name: "", latitude: "")
      }
    end

    assert_response :unprocessable_entity
    assert_select ".tenant-location-form__errors", count: 1
  end

  test "ownerは拠点と代表拠点設定を更新できる" do
    location = create_location(@tenant, name: "更新前")
    @tenant.update!(primary_tenant_location: location)

    patch tenant_location_path(location), params: {
      tenant_location: valid_location_params(name: "更新後"),
      primary_location: "0"
    }

    assert_redirected_to tenant_locations_path
    assert_equal "更新後", location.reload.name
    assert_nil @tenant.reload.primary_tenant_location
  end

  test "掲載から参照中の拠点は削除できない" do
    location = create_location(@tenant, name: "掲載中拠点")
    listing = @tenant.listings.create!(listing_type: "job", title: "拠点参照求人", status: "draft")
    listing.update!(tenant_location: location)

    assert_no_difference -> { TenantLocation.count } do
      delete tenant_location_path(location)
    end

    assert_redirected_to tenant_locations_path
    assert_predicate flash[:alert], :present?
  end

  test "未参照の拠点は削除できる" do
    location = create_location(@tenant, name: "削除対象")

    assert_difference -> { TenantLocation.count }, -1 do
      delete tenant_location_path(location)
    end

    assert_redirected_to tenant_locations_path
  end

  test "staffは拠点一覧を表示できない" do
    @account.tenant_member.update!(role: "staff")

    get tenant_locations_path

    assert_redirected_to tenant_root_path
  end

  test "他テナントの拠点は編集できない" do
    other_tenant, = create_tenant_account(role: "owner", email: "tenant-locations-edit-other@example.com")
    other_location = create_location(other_tenant, name: "他社編集不可")

    get edit_tenant_location_path(other_location)

    assert_response :not_found
  end

  private

  def create_tenant_account(role:, email:)
    tenant = Tenant.create!(name: "Sample Lodge", kana: "サンプルロッジ", status: "active")
    account = TenantAccount.create!(
      email: email,
      password: "password",
      password_confirmation: "password"
    )
    TenantMember.create!(tenant: tenant, account: account, role: role, status: "active")

    [tenant, account]
  end

  def create_location(tenant, name:)
    tenant.tenant_locations.create!(valid_location_params(name: name))
  end

  def valid_location_params(overrides = {})
    {
      name: "本社",
      location_type: "headquarters",
      postal_code: "100-0001",
      prefecture: "東京都",
      city: "千代田区",
      address_line1: "千代田1-1",
      latitude: "35.681236",
      longitude: "139.767125"
    }.merge(overrides)
  end

  def with_google_maps_api_key(value)
    original = ENV["GOOGLE_MAPS_EMBED_API_KEY"]
    value.nil? ? ENV.delete("GOOGLE_MAPS_EMBED_API_KEY") : ENV["GOOGLE_MAPS_EMBED_API_KEY"] = value
    yield
  ensure
    original.nil? ? ENV.delete("GOOGLE_MAPS_EMBED_API_KEY") : ENV["GOOGLE_MAPS_EMBED_API_KEY"] = original
  end
end
