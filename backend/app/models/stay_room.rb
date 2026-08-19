class StayRoom < ApplicationRecord
  belongs_to :stay_listing
  belongs_to :stay_room_type, optional: true

  has_many :stay_beds, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :stay_listing_id }

  validate :stay_room_type_belongs_to_same_stay_listing


  private

  def stay_room_type_belongs_to_same_stay_listing
    return if stay_room_type.blank?
    return if stay_room_type.stay_listing_id == stay_listing_id

    errors.add(:stay_room_type, "は同じ施設の客室タイプを選択してください")
  end

end
