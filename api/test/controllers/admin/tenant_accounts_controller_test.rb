require "test_helper"

class Admin::TenantAccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_account = AdminAccount.create!(
      email: "admin-controller-test@example.com",
      password: "password",
      password_confirmation: "password"
    )
    sign_in @admin_account
  end

  test "creates tenant account organization and owner tenant user" do
    assert_difference -> { TenantAccount.count }, 1 do
      assert_difference -> { Tenant.count }, 1 do
        assert_difference -> { TenantUser.count }, 1 do
          post admin_tenant_accounts_path, params: valid_params
        end
      end
    end

    assert_redirected_to admin_tenant_accounts_path

    tenant_account = TenantAccount.find_by!(email: "owner@example.com")
    tenant_user = tenant_account.tenant_user

    assert_equal "owner", tenant_user.role
    assert_equal "active", tenant_user.status
    assert_equal "Sample Inn", tenant_user.tenant.name
    assert_equal "サンプルイン", tenant_user.tenant.kana
    assert_equal "Tokyo", tenant_user.tenant.address
    assert_equal "active", tenant_user.tenant.status
  end

  test "rolls back tenant account when organization is invalid" do
    invalid_params = valid_params.deep_merge(
      tenant_account: { email: "rollback-owner@example.com" },
      tenant: { name: "" }
    )

    assert_no_difference -> { TenantAccount.count } do
      assert_no_difference -> { Tenant.count } do
        assert_no_difference -> { TenantUser.count } do
          post admin_tenant_accounts_path, params: invalid_params
        end
      end
    end

    assert_response :unprocessable_entity
    assert_nil TenantAccount.find_by(email: "rollback-owner@example.com")
  end

  private

  def valid_params
    {
      tenant_account: {
        email: "owner@example.com",
        password: "password",
        password_confirmation: "password"
      },
      tenant: {
        name: "Sample Inn",
        kana: "サンプルイン",
        address: "Tokyo"
      }
    }
  end
end
