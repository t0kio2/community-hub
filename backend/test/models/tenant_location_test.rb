require "test_helper"

class TenantLocationTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
  end

  test "必須項目があれば拠点は有効" do
    location = build_location

    assert_predicate location, :valid?
  end

  test "同じテナント内で拠点名は重複できない" do
    build_location.save!
    duplicate = build_location

    assert_not_predicate duplicate, :valid?
    assert duplicate.errors[:name].any?
  end

  test "別のテナントでは同じ拠点名を使用できる" do
    build_location.save!
    other_location = build_location(tenant: tenants(:two))

    assert_predicate other_location, :valid?
  end

  test "緯度と経度が範囲外の場合は無効" do
    location = build_location(latitude: 91, longitude: 181)

    assert_not_predicate location, :valid?
    assert location.errors[:latitude].any?
    assert location.errors[:longitude].any?
  end

  test "住所を表示用文字列へまとめられる" do
    location = build_location(
      postal_code: "100-0001",
      prefecture: "東京都",
      city: "千代田区",
      address_line1: "千代田1-1",
      address_line2: "本館"
    )

    assert_equal "100-0001 東京都 千代田区 千代田1-1 本館", location.full_address
  end

  private

  def build_location(tenant: @tenant, **attributes)
    TenantLocation.new(
      {
        tenant: tenant,
        name: "本社",
        location_type: "headquarters",
        latitude: 35.681236,
        longitude: 139.767125
      }.merge(attributes)
    )
  end
end
