class Tenant::ListingsController < Tenant::BaseController
  before_action :require_current_tenant!
  before_action :set_listing, only: [ :show, :edit, :update ]
  before_action :authorize_existing_listing!, only: [ :show, :edit, :update ]

  def index
    type = params[:listing_type]
    authorize @tenant, :index?, with: Tenant::ListingPolicy
    @listings = @tenant.listings.where(listing_type: type).order(updated_at: :desc, id: :desc)
  end

  def show
    set_detail
  end

  def new
    @listing = @tenant.listings.new(listing_type: listing_type_param, status: "draft")
    authorize @listing, :create?, with: Tenant::ListingPolicy
    build_detail
  end

  def create
    @listing = @tenant.listings.new(common_listing_params)
    authorize @listing, :create?, with: Tenant::ListingPolicy
    @listing.created_by_tenant_member = current_tenant_member
    @listing.updated_by_tenant_member = current_tenant_member
    set_status_timestamps
    build_detail
    assign_detail_attributes

    if save_listing_with_detail
      redirect_to tenant_listing_path(@listing), notice: "掲載を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    build_detail
  end

  def update
    @listing.assign_attributes(common_listing_params.except(:listing_type))
    @listing.updated_by_tenant_member = current_tenant_member
    set_status_timestamps
    build_detail
    assign_detail_attributes

    if save_listing_with_detail
      redirect_to tenant_listing_path(@listing), notice: "掲載を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_listing
    return if performed?

    @listing = @tenant.listings.find(params[:id])
  end

  def authorize_existing_listing!
    query = action_name == "show" ? :show? : :update?
    authorize @listing, query, with: Tenant::ListingPolicy
  end

  def set_detail
    @detail = @listing.listing_type == "job" ? @listing.job_listing : @listing.stay_listing
  end

  def build_detail
    @detail =
      if @listing.listing_type == "job"
        @listing.job_listing || @listing.build_job_listing
      else
        @listing.stay_listing || @listing.build_stay_listing
      end
  end

  def assign_detail_attributes
    if @listing.listing_type == "job"
      @detail.assign_attributes(job_listing_params)
    else
      @detail.assign_attributes(stay_listing_params)
    end
  end

  def save_listing_with_detail
    return false unless @listing.valid? && @detail.valid?

    Listing.transaction do
      @listing.save!
      @detail.listing = @listing
      @detail.save!
    end
    true
  end

  def set_status_timestamps
    now = Time.current
    @listing.published_at ||= now if @listing.status == "published"
    @listing.closed_at ||= now if @listing.status == "closed"
  end

  def listing_type_param
    type = params.dig(:listing, :listing_type).presence || params[:listing_type].presence
    Listing::LISTING_TYPES.include?(type) ? type : "job"
  end

  def common_listing_params
    params.require(:listing).permit(:listing_type, :title, :description, :status)
  end

  def job_listing_params
    params.require(:listing).fetch(:job_listing, ActionController::Parameters.new).permit(
      :employment_type,
      :job_category,
      :work_area,
      :work_address,
      :salary_type,
      :salary_min,
      :salary_max,
      :working_hours,
      :work_days,
      :required_skills,
      :welcome_skills,
      :benefits,
      :application_limit
    )
  end

  def stay_listing_params
    params.require(:listing).fetch(:stay_listing, ActionController::Parameters.new).permit(
      :stay_type,
      :address,
      :capacity,
      :price_per_night,
      :check_in_time,
      :check_out_time,
      :available_from,
      :available_until,
      :amenities,
      :house_rules
    )
  end
end
