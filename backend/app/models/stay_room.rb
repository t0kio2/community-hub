class StayRoom < ApplicationRecord
  belongs_to :stay_listing
  belongs_to :stay_room_type, optional: true

  has_many :stay_beds, dependent: :restrict_with_error

end
