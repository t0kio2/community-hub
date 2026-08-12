class Tenant::LocationsController < Tenant::BaseController
  before_action :set_organization
  before_action :set_location, only: %i[edit update destroy]

  def index
    authorize @organization, :index?, with: Tenant::LocationPolicy
    @locations = @organization.tenant_locations.order(:name, :id)
  end

  def new
    @location = @organization.tenant_locations.new(location_type: "other")
    authorize @location, :create?, with: Tenant::LocationPolicy
  end

  def create
    @location = @organization.tenant_locations.new(location_params)
    authorize @location, :create?, with: Tenant::LocationPolicy

    if save_location
      redirect_to tenant_locations_path, notice: "拠点を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @location, :update?, with: Tenant::LocationPolicy
  end

  def update
    authorize @location, :update?, with: Tenant::LocationPolicy
    @location.assign_attributes(location_params)

    if save_location
      redirect_to tenant_locations_path, notice: "拠点を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @location, :destroy?, with: Tenant::LocationPolicy

    if @location.destroy
      redirect_to tenant_locations_path, notice: "拠点を削除しました"
    else
      redirect_to tenant_locations_path, alert: @location.errors.full_messages.to_sentence
    end
  end

  private

  def set_organization
    @organization = current_tenant_organization
    return if @organization

    redirect_to tenant_root_path, alert: "組織情報がありません"
  end

  def set_location
    return if performed?

    @location = @organization.tenant_locations.find(params[:id])
  end

  def location_params
    params.require(:tenant_location).permit(
      :name,
      :location_type,
      :postal_code,
      :prefecture,
      :city,
      :address_line1,
      :address_line2,
      :google_place_id,
      :latitude,
      :longitude
    )
  end

  def save_location
    TenantLocation.transaction do
      @location.save!
      update_primary_location!
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def update_primary_location!
    if primary_location_requested?
      @organization.update!(primary_tenant_location: @location)
    elsif @organization.primary_tenant_location == @location
      @organization.update!(primary_tenant_location: nil)
    end
  end

  def primary_location_requested?
    ActiveModel::Type::Boolean.new.cast(params[:primary_location])
  end
end
