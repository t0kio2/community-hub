require "test_helper"

class AdminTest < ActiveSupport::TestCase
  test "super_adminは有効である" do
    admin = Admin.new(account: accounts(:one), role: "super_admin", status: "active")

    assert admin.valid?
  end

  test "operatorは有効である" do
    admin = Admin.new(account: accounts(:one), role: "operator", status: "active")

    assert admin.valid?
  end

  test "定義されていないロールは無効である" do
    admin = Admin.new(account: accounts(:one), role: "viewer", status: "active")

    assert_not admin.valid?
    assert_includes admin.errors[:role], "is not included in the list"
  end

  test "statusがない管理者は無効である" do
    admin = Admin.new(account: accounts(:one), role: "operator", status: nil)

    assert_not admin.valid?
    assert_includes admin.errors[:status], "can't be blank"
  end
end
