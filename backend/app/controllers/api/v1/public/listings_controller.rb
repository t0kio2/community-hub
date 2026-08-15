class Api::V1::Public::ListingsController < Api::V1::Public::BaseController
  def index
    listings = published_listings.order(published_at: :desc, id: :desc)

    render json: {
      listings: listings.map { |listing| serialize_listing(listing) }
    }
  end

  def show
    listing = published_listings.find(params[:id])

    render json: {
      listing: serialize_listing(listing)
    }
  end

  private

  def published_listings
    Listing
      .where(status: "published")
      .includes(:tenant, :job_listing, :stay_listing)
  end

  def serialize_listing(listing)
    detail = listing.listing_type == "job" ? listing.job_listing : listing.stay_listing

    {
      id: listing.id,
      listing_type: listing.listing_type,
      title: listing.title,
      description: listing.description,
      tenant: {
        id: listing.tenant_id,
        name: listing.tenant.name
      },
      published_at: listing.published_at,
      detail: serialize_detail(listing, detail)
    }
  end

  def serialize_detail(listing, detail)
    return {} if detail.blank?

    if listing.listing_type == "job"
      {
        employment_type: detail.employment_type,
        job_category: detail.job_category,
        work_area: detail.work_area,
        salary_type: detail.salary_type,
        salary_min: detail.salary_min,
        salary_max: detail.salary_max,
        working_hours: detail.working_hours,
        work_days: detail.work_days
      }
    else
      {
        check_in_time: detail.check_in_time,
        latest_check_in_time: detail.latest_check_in_time,
        check_out_time: detail.check_out_time,
        time_zone: detail.time_zone,
        stay_available_starts_on: detail.stay_available_starts_on,
        stay_available_ends_on: detail.stay_available_ends_on,
        house_rules: detail.house_rules
      }
    end
  end
end
