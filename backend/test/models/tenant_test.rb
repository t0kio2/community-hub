require "test_helper"

class TenantTest < ActiveSupport::TestCase
  test "is valid with required attributes" do
    tenant = Tenant.new(name: "Sample Inn", status: "active")

    assert tenant.valid?
  end

  test "requires name" do
    tenant = Tenant.new(status: "active")

    assert_not tenant.valid?
    assert_includes tenant.errors[:name], "can't be blank"
  end

  test "requires status" do
    tenant = Tenant.new(name: "Sample Inn")

    assert_not tenant.valid?
    assert_includes tenant.errors[:status], "can't be blank"
  end
end
