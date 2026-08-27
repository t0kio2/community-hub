class Tenant::StayManagement::SalesCalendarsController < Tenant::StayManagement::BaseController
  def show
    @start_date = selected_month
    @dates = (@start_date..@start_date.end_of_month).to_a
    @room_types = @stay_listing.stay_room_types.order(:name, :id)
    @room_type_rates = StayRoomTypeRate
                       .where(stay_room_type: @room_types, active: true)
                       .joins(:stay_room_type, :stay_rate_plan)
                       .includes(:stay_room_type, :stay_rate_plan)
                       .order("stay_room_types.name", "stay_rate_plans.name", :id)
    @daily_prices = StayRoomTypeRateDailyPrice
                    .where(stay_room_type_rate: @room_type_rates, stay_date: @dates)
                    .index_by { |price| [price.stay_room_type_rate_id, price.stay_date] }
    @daily_sales_controls = StayRoomTypeDailySalesControl
                            .where(stay_room_type: @room_types, stay_date: @dates)
                            .index_by { |control| [control.stay_room_type_id, control.stay_date] }
    set_editor
  end

  private

  def selected_month
    return Date.current.beginning_of_month if params[:month].blank?

    Date.strptime(params[:month], "%Y-%m").beginning_of_month
  rescue Date::Error
    Date.current.beginning_of_month
  end

  def set_editor
    return unless params[:editor].in?(%w[price sales])

    editor_date = Date.iso8601(params[:stay_date])
    return unless editor_date.in?(@dates)

    target_id = params[:target_id].to_i
    if params[:editor] == "price"
      @editor_rate = @room_type_rates.find { |rate| rate.id == target_id }
    else
      @editor_room_type = @room_types.find { |room_type| room_type.id == target_id }
    end
    @editor_date = editor_date if @editor_rate || @editor_room_type
  rescue ArgumentError
    nil
  end
end
