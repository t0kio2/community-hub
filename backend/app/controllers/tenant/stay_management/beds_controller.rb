class Tenant::StayManagement::BedsController < Tenant::StayManagement::BaseController
  before_action :set_room
  before_action :set_bed, only: %i[edit update destroy]

  def new
    @bed = @room.stay_beds.new
  end

  def create
    @bed = @room.stay_beds.new(bed_params)

    if @bed.save
      render_beds_section(notice: "ベッドを登録しました")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @bed.update(bed_params)
      render_beds_section(notice: "ベッドを更新しました")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bed.destroy
    render_beds_section(notice: "ベッドを削除しました")
  end

  private

  def set_room
    @room = @stay_listing.stay_rooms.find(params[:room_id])
  end

  def set_bed
    @bed = @room.stay_beds.find(params[:id])
  end

  def bed_params
    params.require(:stay_bed).permit(:name, :active, :notes)
  end

  def render_beds_section(notice:)
    flash.now[:notice] = notice

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "stay-beds-section",
          partial: "tenant/stay_management/beds/section",
          locals: { listing: @listing, room: @room }
        )
      end
      format.html do
        redirect_to edit_tenant_stay_room_path(@listing, @room), notice: notice
      end
    end
  end

end
