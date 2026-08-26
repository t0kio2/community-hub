class Tenant::StayManagement::RoomBlocksController < Tenant::StayManagement::BaseController
  before_action :set_room
  before_action :set_block, only: %i[edit update destroy]

  def index
    @blocks = @room.stay_room_blocks.order(:starts_on, :ends_on, :id)
  end

  def new
    @block = @room.stay_room_blocks.new
  end

  def create
    @block = @room.stay_room_blocks.new(block_params)

    if @block.save
      redirect_to tenant_stay_room_room_blocks_path(@listing, @room), notice: "客室ブロックを登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @block.update(block_params)
      redirect_to tenant_stay_room_room_blocks_path(@listing, @room), notice: "客室ブロックを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @block.destroy!
    redirect_to tenant_stay_room_room_blocks_path(@listing, @room), notice: "客室ブロックを解除しました"
  end

  private

  def set_room
    @room = @stay_listing.stay_rooms.find(params[:room_id])
  end

  def set_block
    @block = @room.stay_room_blocks.find(params[:id])
  end

  def block_params
    params.require(:stay_room_block).permit(:starts_on, :ends_on, :reason, :notes)
  end
end
