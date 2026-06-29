class Api::V1::User::UserProfilesController < Api::V1::User::BaseController
  def show
    render json: { user_profile: serialize_user_profile(current_user.user_profile) }
  end

  def update
    user_profile = current_user.user_profile || current_user.build_user_profile
    user_profile.assign_attributes(user_profile_params)

    if user_profile.save
      render json: { user_profile: serialize_user_profile(user_profile) }
    else
      render json: { errors: user_profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_profile_params
    params.require(:user_profile).permit(:name, :kana, :birth_date, :phone, :avatar_url)
  end

  def serialize_user_profile(user_profile)
    return nil unless user_profile

    {
      id: user_profile.id,
      name: user_profile.name,
      kana: user_profile.kana,
      birth_date: user_profile.birth_date&.iso8601,
      phone: user_profile.phone,
      avatar_url: user_profile.avatar_url
    }
  end
end
