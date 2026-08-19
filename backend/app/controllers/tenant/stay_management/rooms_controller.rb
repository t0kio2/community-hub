class Tenant::StayManagement::RoomsController < Tenant::StayManagement::BaseController

	before_action :set_room, only: %i[edit update destroy]

	def index
		rooms = @stay_listing.stay_rooms
										.includes(:stay_room_type, :stay_beds)

		if params[:stay_room_type_id].present?
			room_type = @stay_listing.stay_room_types.find(params[:stay_room_type_id])
			rooms = rooms.where(stay_room_type: room_type)
		end

		@rooms = rooms.order(:id)
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
		if @room.update(room_params)
			redirect_to tenant_stay_rooms_path(@listing),
                  notice: "客室を更新しました"
		else
			render :edit, status: :unprocessable_entity
		end
	end

	def destroy
		if @room.destroy
			redirect_to tenant_stay_rooms_path(@listing),
									notice: "客室を削除しました"
		else
			redirect_to tenant_stay_rooms_path(@listing),
                  alert: "ベッドが登録されているため客室を削除できません"
		end
	end

	private

	def set_room
		@room = @stay_listing.stay_rooms.find(params[:id])
	end

	def room_params
		params.require(:stay_room).permit(:name, :stay_room_type_id, :active, :notes)
	end

end
