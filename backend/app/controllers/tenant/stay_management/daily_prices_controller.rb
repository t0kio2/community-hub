class Tenant::StayManagement::DailyPricesController < Tenant::StayManagement::BaseController
  before_action :set_rate_and_date

  def update
    daily_price = @rate.stay_room_type_rate_daily_prices.find_or_initialize_by(stay_date: @stay_date)
    daily_price.assign_attributes(price_params)

    if daily_price.save
      redirect_to calendar_path, notice: "日別料金を設定しました"
    else
      redirect_to calendar_path(editor: "price", target_id: @rate.id, stay_date: @stay_date),
                  alert: daily_price.errors.full_messages.join("、")
    end
  end

  def destroy
    @rate.stay_room_type_rate_daily_prices.find_by(stay_date: @stay_date)&.destroy!
    redirect_to calendar_path, notice: "基本料金へ戻しました"
  end

  private

  def set_rate_and_date
    room_types = @stay_listing.stay_room_types
    @rate = StayRoomTypeRate.where(stay_room_type: room_types).find(params[:stay_room_type_rate_id])
    @stay_date = Date.iso8601(params[:stay_date])
  rescue ArgumentError
    head :unprocessable_entity
  end

  def price_params
    params.require(:daily_price).permit(:price_amount)
  end

  def calendar_path(extra_params = {})
    tenant_stay_sales_calendar_path(
      @listing,
      { month: @stay_date.strftime("%Y-%m") }.merge(extra_params)
    )
  end
end
