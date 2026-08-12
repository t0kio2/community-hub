class Tenant::JobsController < Tenant::BaseController
  before_action :require_current_tenant!
  before_action :set_listing, only: %i[show edit update]
  before_action :authorize_existing_listing!, only: %i[show edit update]

  def index
    authorize @tenant, :index?, with: Tenant::ListingPolicy
    @listings = @tenant.listings.where(listing_type: "job").order(updated_at: :desc, id: :desc)
  end

  def show
    set_or_build_job_detail
  end

  def new
    @listing = @tenant.listings.new(listing_type: "job", status: "draft")
    authorize @listing, :create?, with: Tenant::ListingPolicy
    set_or_build_job_detail
  end

  def create
    @listing = @tenant.listings.new(listing_params.merge(listing_type: "job"))
    authorize @listing, :create?, with: Tenant::ListingPolicy
    set_audit_members
    set_status_timestamps
    set_or_build_job_detail
    @job_listing.assign_attributes(job_listing_params)

    if save_with_job_detail
      redirect_to tenant_job_path(@listing), notice: "求人を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    set_or_build_job_detail
  end

  def update
    @listing.assign_attributes(listing_params)
    @listing.updated_by_tenant_member = current_tenant_member
    set_status_timestamps
    set_or_build_job_detail
    @job_listing.assign_attributes(job_listing_params)

    if save_with_job_detail
      redirect_to tenant_job_path(@listing), notice: "求人を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_listing
    @listing = @tenant.listings.where(listing_type: "job").find(params[:id])
  end

  def authorize_existing_listing!
    authorize @listing, action_name == "show" ? :show? : :update?, with: Tenant::ListingPolicy
  end

  def set_or_build_job_detail
    @job_listing = @listing.job_listing || @listing.build_job_listing
  end

  def set_audit_members
    @listing.created_by_tenant_member = current_tenant_member
    @listing.updated_by_tenant_member = current_tenant_member
  end

  def set_status_timestamps
    now = Time.current
    @listing.published_at ||= now if @listing.status == "published"
    @listing.closed_at ||= now if @listing.status == "closed"
  end

  def save_with_job_detail
    return false unless @listing.valid? && @job_listing.valid?

    Listing.transaction do
      @listing.save!
      @job_listing.listing = @listing
      @job_listing.save!
    end
    true
  end

  def listing_params
    params.require(:listing).permit(:title, :description, :status)
  end

  def job_listing_params
    params.require(:listing).fetch(:job_listing, ActionController::Parameters.new).permit(
      :employment_type, :job_category, :work_area, :work_address, :salary_type,
      :salary_min, :salary_max, :working_hours, :work_days, :required_skills,
      :welcome_skills, :benefits, :application_limit
    )
  end
end
