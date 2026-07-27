require "test_helper"

class TenantAccounts::CreateServiceTest < ActiveSupport::TestCase
  test "TenantAccountとTenantとownerを同じトランザクションで作成する" do
    result = nil

    assert_difference -> { TenantAccount.count }, 1 do
      assert_difference -> { Tenant.count }, 1 do
        assert_difference -> { TenantMember.count }, 1 do
          result = TenantAccounts::CreateService.new(
            account_attributes: {
              email: "created-tenant@example.com",
              password: "password",
              password_confirmation: "password"
            },
            tenant_attributes: {
              name: "作成テナント",
              kana: "サクセイテナント",
              address: "東京都"
            }
          ).call
        end
      end
    end

    assert_predicate result.account, :persisted?
    assert_predicate result.tenant, :persisted?
    assert_predicate result.member, :persisted?
    assert_equal result.account, result.member.account
    assert_equal result.tenant, result.member.tenant
    assert_equal "owner", result.member.role
    assert_equal "active", result.member.status
    assert_equal "active", result.tenant.status
  end

  test "Tenantの保存に失敗した場合はすべてロールバックする" do
    service = TenantAccounts::CreateService.new(
      account_attributes: {
        email: "rollback-tenant@example.com",
        password: "password",
        password_confirmation: "password"
      },
      tenant_attributes: {
        name: "",
        kana: "ロールバック",
        address: "東京都"
      }
    )

    assert_no_difference -> { TenantAccount.count } do
      assert_no_difference -> { Tenant.count } do
        assert_no_difference -> { TenantMember.count } do
          assert_raises(ActiveRecord::RecordInvalid) { service.call }
        end
      end
    end

    assert_not_predicate service.account, :persisted?
    assert_not_predicate service.tenant, :persisted?
    assert_nil service.member
  end
end
