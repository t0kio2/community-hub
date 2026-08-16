class Tenant::StayManagement::RoomTypesController < Tenant::StayManagement::BaseController
  def index
    @room_types = @listing.stay_listing&.stay_room_types&.order(:id) || StayRoomType.none
  end

  def new
    @room_type = stay_listing.stay_room_types.new
  end

  def create
    @room_type = stay_listing.stay_room_types.new(room_type_params)

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

  private

  def stay_listing
    @stay_listing ||= @listing.stay_listing
  end

  def room_type_params
    params.require(:stay_room_type).permit(:name, :description, :room_kind, :capacity, :status)
  end
end
