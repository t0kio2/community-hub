class StayBed < ApplicationRecord
  belongs_to :stay_room

  has_many :stay_bed_blocks, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :stay_room_id }
end
