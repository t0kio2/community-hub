require "test_helper"

class Tenant::LocationsHelperTest < ActionView::TestCase
  test "APIキーと緯度経度からEmbed URLを生成する" do
    with_google_maps_api_key("test-key") do
      url = google_maps_embed_url(latitude: 35.681236, longitude: 139.767125)

      assert_equal(
        "https://www.google.com/maps/embed/v1/view?center=35.681236%2C139.767125&key=test-key&maptype=roadmap&zoom=16",
        url
      )
    end
  end

  test "APIキーがない場合はEmbed URLを生成しない" do
    with_google_maps_api_key(nil) do
      assert_nil google_maps_embed_url(latitude: 35.681236, longitude: 139.767125)
    end
  end

  test "BigDecimalの座標を指数表記にせずEmbed URLへ設定する" do
    with_google_maps_api_key("test-key") do
      url = google_maps_embed_url(
        latitude: BigDecimal("35.681236"),
        longitude: BigDecimal("139.767125")
      )

      assert_includes url, "center=35.681236%2C139.767125"
      assert_no_match(/center=[^&]*e[+-]?\d/i, url)
    end
  end

  private

  def with_google_maps_api_key(value)
    original = ENV["GOOGLE_MAPS_EMBED_API_KEY"]
    value.nil? ? ENV.delete("GOOGLE_MAPS_EMBED_API_KEY") : ENV["GOOGLE_MAPS_EMBED_API_KEY"] = value
    yield
  ensure
    original.nil? ? ENV.delete("GOOGLE_MAPS_EMBED_API_KEY") : ENV["GOOGLE_MAPS_EMBED_API_KEY"] = original
  end
end
