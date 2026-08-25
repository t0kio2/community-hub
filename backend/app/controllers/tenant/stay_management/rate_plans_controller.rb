class Tenant::StayManagement::RatePlansController < Tenant::StayManagement::BaseController
  before_action :set_rate_plan, only: %i[show edit update destroy]

  def index
    @rate_plans = @stay_listing.stay_rate_plans
                               .includes(stay_room_type_rates: :stay_room_type)
                               .order(:id)
  end

  def show
    @room_type_rates = @rate_plan.stay_room_type_rates
                                 .includes(:stay_room_type)
                                 .order(:stay_room_type_id)
  end

  def new
    @rate_plan = @stay_listing.stay_rate_plans.new
    prepare_room_type_rates
  end

  def create
    @rate_plan = @stay_listing.stay_rate_plans.new(rate_plan_params)

    if @rate_plan.save
      redirect_to tenant_stay_rate_plan_path(@listing, @rate_plan),
                  notice: "料金プランを登録しました"
    else
      prepare_room_type_rates
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    prepare_room_type_rates
  end

  def update
    if @rate_plan.update(rate_plan_params)
      redirect_to tenant_stay_rate_plan_path(@listing, @rate_plan),
                  notice: "料金プランを更新しました"
    else
      prepare_room_type_rates
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @rate_plan.destroyable?
      redirect_to tenant_stay_rate_plan_path(@listing, @rate_plan),
                  alert: "公開中、または基本料金が設定されている料金プランは削除できません"
      return
    end

    @rate_plan.destroy!
    redirect_to tenant_stay_rate_plans_path(@listing), notice: "料金プランを削除しました"
  end

  private

  def set_rate_plan
    @rate_plan = @stay_listing.stay_rate_plans.find(params[:id])
  end

  def prepare_room_type_rates
    @room_types = @stay_listing.stay_room_types.order(:id)
    rates_by_room_type_id = @rate_plan.stay_room_type_rates.index_by(&:stay_room_type_id)

    @room_type_rates = @room_types.map do |room_type|
      rates_by_room_type_id[room_type.id] ||
        @rate_plan.stay_room_type_rates.build(stay_room_type: room_type, active: false)
    end
  end

  def rate_plan_params
    params.require(:stay_rate_plan).permit(
      :name,
      :description,
      :meal_type,
      :cancellation_policy_type,
      :status,
      stay_room_type_rates_attributes: %i[
        id
        stay_room_type_id
        price_per_night_amount
        active
      ]
    )
  end
end
