require "test_helper"

class Admin::TenantAccountPolicyTest < ActiveSupport::TestCase
  test "super_adminはテナントアカウントを管理・削除できる" do
    policy = Admin::TenantAccountPolicy.new(admin(role: "super_admin"), TenantAccount)

    assert_predicate policy, :index?
    assert_predicate policy, :show?
    assert_predicate policy, :create?
    assert_predicate policy, :update?
    assert_predicate policy, :destroy?
  end

  test "operatorはテナントアカウントを管理できるが削除できない" do
    policy = Admin::TenantAccountPolicy.new(admin(role: "operator"), TenantAccount)

    assert_predicate policy, :index?
    assert_predicate policy, :show?
    assert_predicate policy, :create?
    assert_predicate policy, :update?
    assert_not_predicate policy, :destroy?
  end

  test "無効な管理者はテナントアカウントを操作できない" do
    policy = Admin::TenantAccountPolicy.new(admin(role: "super_admin", status: "inactive"), TenantAccount)

    assert_not_predicate policy, :index?
    assert_not_predicate policy, :show?
    assert_not_predicate policy, :create?
    assert_not_predicate policy, :update?
    assert_not_predicate policy, :destroy?
  end

  private

  def admin(role:, status: "active")
    Admin.new(role: role, status: status)
  end
end
