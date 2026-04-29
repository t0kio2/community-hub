require "test_helper"

class Tenant::OrganizationsControllerTest < ActionDispatch::IntegrationTest
  test "ownerは組織情報編集画面を表示できる" do
    tenant, account = create_tenant_account(role: "owner", email: "tenant-org-edit-owner@example.com")
    sign_in account

    get edit_tenant_organization_path

    assert_response :success
    assert_includes response.body, "組織情報を編集"
    assert_includes response.body, tenant.name
  end

  test "ownerは組織情報を更新できる" do
    tenant, account = create_tenant_account(role: "owner", email: "tenant-org-update-owner@example.com")
    sign_in account

    patch tenant_organization_path, params: {
      tenant: {
        name: "Updated Lodge",
        kana: "アップデートロッジ",
        address: "Osaka"
      }
    }

    assert_redirected_to tenant_root_path
    tenant.reload
    assert_equal "Updated Lodge", tenant.name
    assert_equal "アップデートロッジ", tenant.kana
    assert_equal "Osaka", tenant.address
    assert_equal "active", tenant.status
  end

  test "組織名が空の場合は更新しない" do
    tenant, account = create_tenant_account(role: "owner", email: "tenant-org-invalid-owner@example.com")
    sign_in account

    patch tenant_organization_path, params: {
      tenant: {
        name: "",
        kana: "アップデートロッジ",
        address: "Osaka"
      }
    }

    assert_response :unprocessable_entity
    tenant.reload
    assert_equal "Sample Lodge", tenant.name
    assert_equal "サンプルロッジ", tenant.kana
    assert_equal "Tokyo", tenant.address
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
        kana: "スタッフロッジ",
        address: "Kyoto"
      }
    }

    assert_redirected_to tenant_root_path
    tenant.reload
    assert_equal "Sample Lodge", tenant.name
    assert_equal "サンプルロッジ", tenant.kana
    assert_equal "Tokyo", tenant.address
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
end
