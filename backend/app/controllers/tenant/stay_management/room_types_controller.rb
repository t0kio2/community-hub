class Tenant::StayManagement::RoomTypesController < Tenant::StayManagement::BaseController
  def index
    @room_types = @listing.stay_listing&.stay_room_types&.order(:id) || StayRoomType.none
  end

	def new
		@room_type = StayRoomType.new
	end

	def create
	end
end
