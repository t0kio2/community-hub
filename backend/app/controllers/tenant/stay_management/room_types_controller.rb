class Tenant::StayManagement::RoomTypesController < Tenant::StayManagement::BaseController

	before_action :set_room_type, only: %i[edit update destroy]


  def index
    @room_types = @stay_listing.stay_room_types
															.includes(:stay_rooms)
															.order(:id)
  end

  def new
    @room_type = @stay_listing.stay_room_types.new
  end

  def create
    @room_type = @stay_listing.stay_room_types.new(room_type_params)

    if @room_type.save
      redirect_to tenant_stay_room_types_path(@listing), notice: "客室タイプを登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

	def edit	
	end

	def update
	end

	def destroy
		@room_type.destroy
		redirect_to tenant_stay_room_types_path(@listing), notice: "客室タイプを削除しました"
	end


  private

	def set_room_type
		@room_type = @stay_listing.stay_room_types.find(params[:id])
	end

  def room_type_params
    params.require(:stay_room_type).permit(:name, :description, :room_kind, :capacity, :status)
  end
end
