class StayRoomType < ApplicationRecord
  ROOM_KINDS = %w[private_room shared_room entire_place].freeze
  STATUSES = %w[draft published inactive].freeze

  belongs_to :stay_listing

  has_many :stay_rooms, dependent: :nullify

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: { scope: :stay_listing_id }
  validates :room_kind, inclusion: { in: ROOM_KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  validate :shared_room_capacity, if: :shared_room?

  enum :room_kind, ROOM_KINDS.index_with(&:itself)
  enum :status, STATUSES.index_with(&:itself)

  private

  def shared_room_capacity
    return if capacity == 1
    errors.add(:capacity, "は、#{I18n.t("activerecord.enums.stay_room_type.room_kind.#{room_kind}")}の場合は1を設定してください")
  end

end
