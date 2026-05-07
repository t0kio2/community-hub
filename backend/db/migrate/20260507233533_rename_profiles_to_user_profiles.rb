class RenameProfilesToUserProfiles < ActiveRecord::Migration[8.1]
  def up
    rename_table :profiles, :user_profiles
    if index_exists?(:user_profiles, :user_id, name: "index_profiles_on_user_id")
      rename_index :user_profiles,
        "index_profiles_on_user_id",
        "index_user_profiles_on_user_id"
    end
  end

  def down
    rename_table :user_profiles, :profiles
    if index_exists?(:profiles, :user_id, name: "index_user_profiles_on_user_id")
      rename_index :profiles,
        "index_user_profiles_on_user_id",
        "index_profiles_on_user_id"
    end
  end
end
