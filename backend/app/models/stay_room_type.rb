class StayRoomType < ApplicationRecord
  ROOM_KINDS = %w[private_room shared_room entire_place].freeze
  STATUSES = %w[draft published inactive].freeze

  belongs_to :stay_listing

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: { scope: :stay_listing_id }
  validates :room_kind, inclusion: { in: ROOM_KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  enum :room_kind, ROOM_KINDS.index_with(&:itself)
  enum :status, STATUSES.index_with(&:itself)
end
