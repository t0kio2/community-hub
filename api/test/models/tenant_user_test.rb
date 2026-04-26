require "test_helper"

class TenantUserTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(
      email: "tenant-member@example.com",
      account_type: "tenant"
    )
    @tenant = Tenant.create!(name: "Sample Inn", status: "active")
  end

  test "is valid with owner role" do
    tenant_user = TenantUser.new(
      account: @account,
      tenant: @tenant,
      role: "owner",
      status: "active"
    )

    assert tenant_user.valid?
  end

  test "is valid with staff role" do
    tenant_user = TenantUser.new(
      account: @account,
      tenant: @tenant,
      role: "staff",
      status: "active"
    )

    assert tenant_user.valid?
  end

  test "rejects unknown role" do
    tenant_user = TenantUser.new(
      account: @account,
      tenant: @tenant,
      role: "manager",
      status: "active"
    )

    assert_not tenant_user.valid?
    assert_includes tenant_user.errors[:role], "is not included in the list"
  end

  test "requires status" do
    tenant_user = TenantUser.new(
      account: @account,
      tenant: @tenant,
      role: "owner"
    )

    assert_not tenant_user.valid?
    assert_includes tenant_user.errors[:status], "can't be blank"
  end
end
