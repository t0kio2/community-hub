class StayRoomType < ApplicationRecord

	belongs_to :stay_listing, optional: true


end