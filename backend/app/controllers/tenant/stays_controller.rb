class Tenant::StaysController < Tenant::BaseController
  layout :tenant_stay_layout

  before_action :require_current_tenant!
  before_action :set_listing, only: %i[show edit update]
  before_action :authorize_existing_listing!, only: %i[show edit update]

  def index
    authorize @tenant, :index?, with: Tenant::ListingPolicy
    @listings = @tenant.listings.where(listing_type: "stay")
    .order(updated_at: :desc, id: :desc)
  end

  def show
    set_or_build_stay_detail
  end

  def new
    @listing = @tenant.listings.new(listing_type: "stay", status: "draft")
    authorize @listing, :create?, with: Tenant::ListingPolicy
    set_or_build_stay_detail
  end

  def create
    @listing = @tenant.listings.new(listing_params.merge(listing_type: "stay", status: "draft"))
    authorize @listing, :create?, with: Tenant::ListingPolicy
    set_audit_members
    set_or_build_stay_detail
    @stay_listing.assign_attributes(stay_listing_params)

    if save_with_stay_detail
      redirect_to tenant_stay_path(@listing), notice: "宿泊施設を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    set_or_build_stay_detail
  end

  def update
    @listing.assign_attributes(listing_params)
    @listing.updated_by_tenant_member = current_tenant_member
    set_or_build_stay_detail
    @stay_listing.assign_attributes(stay_listing_params)

    if save_with_stay_detail
      redirect_to tenant_stay_path(@listing), notice: "宿泊施設を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def tenant_stay_layout
    layout_stay = "tenant/stay"
    layout_tenant = "tenant"

    case action_name
    when "show"
      layout_stay
    when "edit"
      layout_stay
    else
      layout_tenant
    end

  end

  def set_listing
    @listing = @tenant.listings.where(listing_type: "stay").find(params[:id])
  end

  def authorize_existing_listing!
    authorize @listing, action_name == "show" ? :show? : :update?, with: Tenant::ListingPolicy
  end

  def set_or_build_stay_detail
    @stay_listing = @listing.stay_listing || @listing.build_stay_listing
  end

  def set_audit_members
    @listing.created_by_tenant_member = current_tenant_member
    @listing.updated_by_tenant_member = current_tenant_member
  end

  def save_with_stay_detail
    return false unless @listing.valid? && @stay_listing.valid?

    Listing.transaction do
      @listing.save!
      @stay_listing.listing = @listing
      @stay_listing.save!
    end
    true
  end

  def listing_params
    params.require(:listing).permit(:title, :description, :tenant_location_id)
  end

  def stay_listing_params
    params.require(:listing).fetch(:stay_listing, {}).permit(
      :check_in_time,
      :latest_check_in_time,
      :check_out_time,
      :time_zone,
      :booking_confirmation_mode,
      :approval_deadline_hours,
      :booking_open_days_before,
      :booking_close_hours_before,
      :stay_available_starts_on,
      :stay_available_ends_on,
      :house_rules
    )
  end
end
