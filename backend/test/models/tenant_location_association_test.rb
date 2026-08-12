require "test_helper"

class TenantLocationAssociationTest < ActiveSupport::TestCase
  test "テナントは所有する拠点を代表拠点に設定できる" do
    tenant = tenants(:one)
    location = create_location(tenant)

    tenant.primary_tenant_location = location

    assert_predicate tenant, :valid?
  end

  test "テナントは他テナントの拠点を代表拠点に設定できない" do
    tenant = tenants(:one)
    other_location = create_location(tenants(:two))

    tenant.primary_tenant_location = other_location

    assert_not_predicate tenant, :valid?
    assert_includes tenant.errors[:primary_tenant_location], "は同じテナントの拠点を指定してください"
  end

  test "掲載は他テナントの拠点を指定できない" do
    listing = listings(:job)
    other_location = create_location(tenants(:two))

    listing.tenant_location = other_location

    assert_not_predicate listing, :valid?
    assert_includes listing.errors[:tenant_location], "は同じテナントの拠点を指定してください"
  end

  private

  def create_location(tenant)
    tenant.tenant_locations.create!(
      name: "#{tenant.name}の本社",
      location_type: "headquarters",
      latitude: 35.681236,
      longitude: 139.767125
    )
  end
end
