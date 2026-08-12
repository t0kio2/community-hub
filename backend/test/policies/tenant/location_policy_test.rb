require "test_helper"

class Tenant::LocationPolicyTest < ActiveSupport::TestCase
  test "ownerは所属テナントの拠点を管理できる" do
    policy = Tenant::LocationPolicy.new(member(role: "owner"), location(tenant_id: 1))

    assert_predicate policy, :index?
    assert_predicate policy, :create?
    assert_predicate policy, :update?
    assert_predicate policy, :destroy?
  end

  test "staffは拠点を管理できない" do
    policy = Tenant::LocationPolicy.new(member(role: "staff"), location(tenant_id: 1))

    assert_not_predicate policy, :index?
    assert_not_predicate policy, :create?
    assert_not_predicate policy, :update?
    assert_not_predicate policy, :destroy?
  end

  test "ownerでも他テナントの拠点は管理できない" do
    policy = Tenant::LocationPolicy.new(member(role: "owner"), location(tenant_id: 2))

    assert_not_predicate policy, :update?
    assert_not_predicate policy, :destroy?
  end

  private

  def location(tenant_id:)
    TenantLocation.new(tenant_id: tenant_id)
  end

  def member(role:)
    TenantMember.new(tenant_id: 1, role: role, status: "active")
  end
end
