class Tenant::StayManagement::BaseController < Tenant::BaseController
	layout "tenant/stay"

	before_action :require_current_tenant!
	before_action :set_listing

	private

	def set_listing
		@listing = @tenant.listings
											.where(listing_type: "stay")
											.find(params[:stay_id])
	end

end