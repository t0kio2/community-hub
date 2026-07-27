require "test_helper"

class Tenant::ListingPolicyTest < ActiveSupport::TestCase
  test "ownerとstaffは所属テナントの掲載を操作できる" do
    %w[owner staff].each do |role|
      policy = Tenant::ListingPolicy.new(member(role: role), listing)

      assert_predicate policy, :show?
      assert_predicate policy, :create?
      assert_predicate policy, :update?
    end
  end

  test "他テナントの掲載は操作できない" do
    other_listing = Listing.new(tenant_id: 2)
    policy = Tenant::ListingPolicy.new(member(role: "owner"), other_listing)

    assert_not_predicate policy, :show?
    assert_not_predicate policy, :create?
    assert_not_predicate policy, :update?
  end

  test "無効なメンバーは掲載を操作できない" do
    policy = Tenant::ListingPolicy.new(member(role: "owner", status: "inactive"), listing)

    assert_not_predicate policy, :index?
    assert_not_predicate policy, :show?
    assert_not_predicate policy, :create?
    assert_not_predicate policy, :update?
  end

  private

  def listing
    Listing.new(tenant_id: 1)
  end

  def member(role:, status: "active")
    TenantMember.new(tenant_id: 1, role: role, status: status)
  end
end
