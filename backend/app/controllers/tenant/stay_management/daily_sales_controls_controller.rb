class Tenant::StayManagement::DailySalesControlsController < Tenant::StayManagement::BaseController
  before_action :set_room_type_and_date

  def update
    control = @room_type.stay_room_type_daily_sales_controls.find_or_initialize_by(stay_date: @stay_date)
    control.assign_attributes(control_params)

    if control.save
      redirect_to calendar_path, notice: control.sales_limit.zero? ? "販売停止に設定しました" : "販売上限を設定しました"
    else
      redirect_to calendar_path(editor: "sales", target_id: @room_type.id, stay_date: @stay_date),
                  alert: control.errors.full_messages.join("、")
    end
  end

  def destroy
    @room_type.stay_room_type_daily_sales_controls.find_by(stay_date: @stay_date)&.destroy!
    redirect_to calendar_path, notice: "販売上限なしへ戻しました"
  end

  private

  def set_room_type_and_date
    @room_type = @stay_listing.stay_room_types.find(params[:stay_room_type_id])
    @stay_date = Date.iso8601(params[:stay_date])
  rescue ArgumentError
    head :unprocessable_entity
  end

  def control_params
    params.require(:daily_sales_control).permit(:sales_limit)
  end

  def calendar_path(extra_params = {})
    tenant_stay_sales_calendar_path(
      @listing,
      { month: @stay_date.strftime("%Y-%m") }.merge(extra_params)
    )
  end
end
