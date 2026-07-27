require "test_helper"

class Tenant::OrganizationPolicyTest < ActiveSupport::TestCase
  test "ownerは所属テナントの組織を表示・更新できる" do
    policy = Tenant::OrganizationPolicy.new(member(role: "owner"), tenant)

    assert_predicate policy, :show?
    assert_predicate policy, :update?
  end

  test "staffは所属テナントの組織を表示できるが更新できない" do
    policy = Tenant::OrganizationPolicy.new(member(role: "staff"), tenant)

    assert_predicate policy, :show?
    assert_not_predicate policy, :update?
  end

  test "無効なメンバーはownerでも更新できない" do
    policy = Tenant::OrganizationPolicy.new(member(role: "owner", status: "inactive"), tenant)

    assert_not_predicate policy, :show?
    assert_not_predicate policy, :update?
  end

  test "他テナントの組織は更新できない" do
    policy = Tenant::OrganizationPolicy.new(member(role: "owner"), Tenant.new(id: 2))

    assert_not_predicate policy, :show?
    assert_not_predicate policy, :update?
  end

  private

  def tenant
    Tenant.new(id: 1)
  end

  def member(role:, status: "active")
    TenantMember.new(tenant_id: 1, role: role, status: status)
  end
end
