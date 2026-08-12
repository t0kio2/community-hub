require "test_helper"

class Tenant::OrganizationsControllerTest < ActionDispatch::IntegrationTest
  test "ownerは組織情報編集画面を表示できる" do
    tenant, account = create_tenant_account(role: "owner", email: "tenant-org-edit-owner@example.com")
    sign_in account

    get edit_tenant_organization_path

    assert_response :success
    assert_select 'link[rel="stylesheet"][href*="organizations"]', count: 1
    assert_select "h1#tenant-page-title", text: "組織情報を編集"
    assert_select ".tenant-content > .tenant-organization-edit", count: 1
    assert_select ".tenant-topbar .tenant-back-link[href=?]", tenant_root_path, text: "← ホームへ戻る"
    assert_select ".tenant-organization-edit__card", count: 2
    assert_select ".tenant-organization-edit__submit", count: 1
    assert_select ".tenant-organization-edit__actions a", count: 0
    assert_select 'input[name="tenant[address]"]', count: 0
    assert_select ".tenant-content style", count: 0
    assert_includes response.body, "組織情報を編集"
    assert_includes response.body, tenant.name
  end

  test "拠点が未登録の場合は登録導線を表示する" do
    _tenant, account = create_tenant_account(role: "owner", email: "tenant-org-location-empty@example.com")
    sign_in account

    get edit_tenant_organization_path

    assert_response :success
    assert_select ".tenant-organization-locations__empty", count: 1
    assert_select ".tenant-organization-locations__register[href=?]", new_tenant_location_path, text: "拠点を登録"
    assert_select ".tenant-organization-location", count: 0
  end

  test "登録済みの拠点を表示して編集できる" do
    tenant, account = create_tenant_account(role: "owner", email: "tenant-org-location-present@example.com")
    primary_location = create_location(tenant, name: "本社", prefecture: "東京都")
    other_location = create_location(tenant, name: "宿泊施設", prefecture: "長野県")
    tenant.update!(primary_tenant_location: primary_location)
    sign_in account

    get edit_tenant_organization_path

    assert_response :success
    assert_select ".tenant-organization-locations__empty", count: 0
    assert_select ".tenant-organization-location", count: 2
    assert_select ".tenant-organization-location__heading span", text: "代表拠点", count: 1
    assert_select ".tenant-organization-location__edit[href=?]", edit_tenant_location_path(primary_location), count: 1
    assert_select ".tenant-organization-location__edit[href=?]", edit_tenant_location_path(other_location), count: 1
    assert_select ".tenant-organization-locations__add[href=?]", new_tenant_location_path, count: 1
    assert_includes response.body, "東京都"
    assert_includes response.body, "長野県"
  end

  test "ownerは組織情報を更新できる" do
    tenant, account = create_tenant_account(role: "owner", email: "tenant-org-update-owner@example.com")
    sign_in account

    patch tenant_organization_path, params: {
      tenant: {
        name: "Updated Lodge",
        kana: "アップデートロッジ"
      }
    }

    assert_redirected_to tenant_root_path
    tenant.reload
    assert_equal "Updated Lodge", tenant.name
    assert_equal "アップデートロッジ", tenant.kana
    assert_equal "active", tenant.status
  end

  test "組織名が空の場合は更新しない" do
    tenant, account = create_tenant_account(role: "owner", email: "tenant-org-invalid-owner@example.com")
    sign_in account

    patch tenant_organization_path, params: {
      tenant: {
        name: "",
        kana: "アップデートロッジ"
      }
    }

    assert_response :unprocessable_entity
    tenant.reload
    assert_equal "Sample Lodge", tenant.name
    assert_equal "サンプルロッジ", tenant.kana
  end

  test "staffは組織情報編集画面を表示できない" do
    tenant, account = create_tenant_account(role: "staff", email: "tenant-org-edit-staff@example.com")
    sign_in account

    get edit_tenant_organization_path

    assert_redirected_to tenant_root_path
    assert_equal "Sample Lodge", tenant.reload.name
  end

  test "staffは組織情報を更新できない" do
    tenant, account = create_tenant_account(role: "staff", email: "tenant-org-update-staff@example.com")
    sign_in account

    patch tenant_organization_path, params: {
      tenant: {
        name: "Staff Updated Lodge",
        kana: "スタッフロッジ"
      }
    }

    assert_redirected_to tenant_root_path
    tenant.reload
    assert_equal "Sample Lodge", tenant.name
    assert_equal "サンプルロッジ", tenant.kana
  end

  private

  def create_tenant_account(role:, email:)
    tenant = Tenant.create!(
      name: "Sample Lodge",
      kana: "サンプルロッジ",
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

  def create_location(tenant, name:, prefecture:)
    tenant.tenant_locations.create!(
      name: name,
      location_type: "facility",
      prefecture: prefecture,
      city: "サンプル市",
      address_line1: "1-1",
      latitude: 35.681236,
      longitude: 139.767125
    )
  end
end
