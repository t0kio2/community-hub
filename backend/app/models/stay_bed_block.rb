class StayBedBlock < ApplicationRecord
  REASONS = StayRoomBlock::REASONS

  belongs_to :stay_bed

  validates :starts_on, :ends_on, presence: true
  validates :reason, inclusion: { in: REASONS }
  validate :ends_on_is_after_starts_on
  validate :bed_belongs_to_shared_room

  private

  def ends_on_is_after_starts_on
    return if starts_on.blank? || ends_on.blank? || ends_on > starts_on

    errors.add(:ends_on, "は停止する最初の宿泊日より後にしてください")
  end

  def bed_belongs_to_shared_room
    return if stay_bed.blank? || stay_bed.stay_room.stay_room_type&.shared_room?

    errors.add(:stay_bed, "は相部屋に所属するベッドを選択してください")
  end
end
