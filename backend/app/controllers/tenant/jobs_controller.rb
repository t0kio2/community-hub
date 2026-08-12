class Tenant::JobsController < Tenant::BaseController
  before_action :require_current_tenant!

  def index
    authorize @tenant, :index?, with: Tenant::ListingPolicy
    @listings = @tenant.listings.where(listing_type: "job").order(updated_at: :desc, id: :desc)
  end
end
