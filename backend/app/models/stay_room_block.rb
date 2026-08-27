class StayRoomBlock < ApplicationRecord
  REASONS = %w[maintenance cleaning operator_block other].freeze

  belongs_to :stay_room

  validates :starts_on, :ends_on, presence: true
  validates :reason, inclusion: { in: REASONS }
  validate :ends_on_is_after_starts_on

  private

  def ends_on_is_after_starts_on
    return if starts_on.blank? || ends_on.blank? || ends_on > starts_on

    errors.add(:ends_on, "は停止する最初の宿泊日より後にしてください")
  end
end
