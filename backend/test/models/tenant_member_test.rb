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

  test "削除時に掲載の作成者と更新者参照を空にする" do
    tenant_member = TenantMember.create!(
      account: @account,
      tenant: @tenant,
      role: "owner",
      status: "active"
    )
    listing = Listing.create!(
      tenant: @tenant,
      created_by_tenant_member: tenant_member,
      updated_by_tenant_member: tenant_member,
      listing_type: "job",
      title: "削除確認用の求人",
      status: "draft"
    )

    tenant_member.destroy!

    listing.reload
    assert_nil listing.created_by_tenant_member_id
    assert_nil listing.updated_by_tenant_member_id
  end
end
