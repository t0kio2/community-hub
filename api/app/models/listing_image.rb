class ListingImage < ApplicationRecord
  belongs_to :listing

  validates :image_url, presence: true
  validates :position,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :listing_id }
end
