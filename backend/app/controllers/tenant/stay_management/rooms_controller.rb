class Tenant::StayManagement::RoomsController < Tenant::StayManagement::BaseController

	def index
		set_rooms
	end

	def new
		@room = @stay_listing.stay_rooms.new
	end

	def create
		@room = @stay_listing.stay_rooms.new(room_params)

		if @room.save
			redirect_to tenant_stay_rooms_path(@listing), notice: "客室を登録しました"
		else
			render :new, status: :unprocessable_entity
		end
	end

	def edit
	end

	def update
	end

	def destroy
	end

	private

	def set_rooms
		@rooms = @stay_listing.stay_rooms
	end

	def room_params
		params.require(:stay_room).permit(:name, :stay_room_type_id, :active, :notes)
	end

end