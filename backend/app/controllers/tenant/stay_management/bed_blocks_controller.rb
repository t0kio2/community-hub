class Tenant::StayManagement::BedBlocksController < Tenant::StayManagement::BaseController
  before_action :set_room
  before_action :set_bed
  before_action :set_block, only: %i[edit update destroy]

  def index
    @blocks = @bed.stay_bed_blocks.order(:starts_on, :ends_on, :id)
  end

  def new
    @block = @bed.stay_bed_blocks.new
  end

  def create
    @block = @bed.stay_bed_blocks.new(block_params)

    if @block.save
      redirect_to tenant_stay_room_bed_bed_blocks_path(@listing, @room, @bed), notice: "ベッドブロックを登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @block.update(block_params)
      redirect_to tenant_stay_room_bed_bed_blocks_path(@listing, @room, @bed), notice: "ベッドブロックを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @block.destroy!
    redirect_to tenant_stay_room_bed_bed_blocks_path(@listing, @room, @bed), notice: "ベッドブロックを解除しました"
  end

  private

  def set_room
    @room = @stay_listing.stay_rooms.find(params[:room_id])
  end

  def set_bed
    @bed = @room.stay_beds.find(params[:bed_id])
  end

  def set_block
    @block = @bed.stay_bed_blocks.find(params[:id])
  end

  def block_params
    params.require(:stay_bed_block).permit(:starts_on, :ends_on, :reason, :notes)
  end
end
