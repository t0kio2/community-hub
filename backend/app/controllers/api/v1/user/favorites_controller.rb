class Api::V1::User::FavoritesController < Api::V1::User::BaseController
  def index
    favorites = current_user
      .favorites
      .includes(listing: [:tenant, :job_listing, :stay_listing])
      .order(created_at: :desc, id: :desc)

    render json: {
      favorites: favorites.map { |favorite| serialize_favorite(favorite) }
    }
  end

  def create
    listing = Listing.where(status: "published").find(params.require(:listing_id))
    favorite = current_user.favorites.find_or_create_by!(listing: listing)

    render json: {
      favorite: serialize_favorite(favorite)
    }, status: :created
  end

  def destroy
    favorite = current_user.favorites.find(params[:id])
    favorite.destroy!

    head :no_content
  end

  private

  def serialize_favorite(favorite)
    listing = favorite.listing

    {
      id: favorite.id,
      listing: {
        id: listing.id,
        listing_type: listing.listing_type,
        title: listing.title,
        tenant: {
          id: listing.tenant_id,
          name: listing.tenant.name
        }
      },
      created_at: favorite.created_at
    }
  end
end

