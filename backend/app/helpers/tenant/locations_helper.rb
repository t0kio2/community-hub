module Tenant::LocationsHelper
  GOOGLE_MAPS_EMBED_BASE_URL = "https://www.google.com/maps/embed/v1/view".freeze

  def google_maps_embed_api_key
    ENV["GOOGLE_MAPS_EMBED_API_KEY"].presence
  end

  def google_maps_embed_url(latitude:, longitude:)
    return if google_maps_embed_api_key.blank? || latitude.blank? || longitude.blank?

    query = {
      key: google_maps_embed_api_key,
      center: coordinates_for_url(latitude, longitude),
      zoom: 16,
      maptype: "roadmap"
    }.to_query

    "#{GOOGLE_MAPS_EMBED_BASE_URL}?#{query}"
  end

  def google_maps_search_url(latitude:, longitude:)
    "https://www.google.com/maps/search/?#{{
      api: 1,
      query: coordinates_for_url(latitude, longitude)
    }.to_query}"
  end

  private

  def coordinates_for_url(latitude, longitude)
    [latitude, longitude].map { |coordinate| coordinate.to_d.to_s("F") }.join(",")
  end
end
