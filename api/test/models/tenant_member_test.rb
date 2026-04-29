require "test_helper"

class TenantMemberTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(
      email: "tenant-member@example.com",
      account_type: "tenant"
    )
    @tenant = Tenant.create!(name: "Sample Inn", status: "active")
  end

  test "is valid with owner role" do
    tenant_member = TenantMember.new(
      account: @account,
      tenant: @tenant,
      role: "owner",
      status: "active"
    )

    assert tenant_member.valid?
  end

  test "is valid with staff role" do
    tenant_member = TenantMember.new(
      account: @account,
      tenant: @tenant,
      role: "staff",
      status: "active"
    )

    assert tenant_member.valid?
  end

  test "rejects unknown role" do
    tenant_member = TenantMember.new(
      account: @account,
      tenant: @tenant,
      role: "manager",
      status: "active"
    )

    assert_not tenant_member.valid?
    assert_includes tenant_member.errors[:role], "is not included in the list"
  end

  test "requires status" do
    tenant_member = TenantMember.new(
      account: @account,
      tenant: @tenant,
      role: "owner"
    )

    assert_not tenant_member.valid?
    assert_includes tenant_member.errors[:status], "can't be blank"
  end
end
