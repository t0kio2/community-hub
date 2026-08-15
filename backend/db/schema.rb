# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_15_001000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "account_type", default: "", null: false, comment: "user|tenant|admin"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["account_type"], name: "index_accounts_on_account_type"
    t.index ["email"], name: "index_accounts_on_email", unique: true
    t.index ["reset_password_token"], name: "index_accounts_on_reset_password_token", unique: true
  end

  create_table "admins", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_admins_on_account_id", unique: true
    t.check_constraint "role::text = ANY (ARRAY['super_admin'::character varying, 'operator'::character varying]::text[])", name: "admins_role_check"
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "listing_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["listing_id"], name: "index_favorites_on_listing_id"
    t.index ["user_id", "listing_id"], name: "index_favorites_on_user_id_and_listing_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "job_listings", force: :cascade do |t|
    t.integer "application_limit"
    t.text "benefits"
    t.datetime "created_at", null: false
    t.string "employment_type"
    t.string "job_category"
    t.bigint "listing_id", null: false
    t.text "required_skills"
    t.integer "salary_max"
    t.integer "salary_min"
    t.string "salary_type"
    t.datetime "updated_at", null: false
    t.text "welcome_skills"
    t.string "work_address"
    t.string "work_area"
    t.string "work_days"
    t.string "working_hours"
    t.index ["listing_id"], name: "index_job_listings_on_listing_id", unique: true
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp"
    t.string "jti"
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "listing_images", force: :cascade do |t|
    t.string "alt_text"
    t.datetime "created_at", null: false
    t.string "image_url", null: false
    t.bigint "listing_id", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id", "position"], name: "index_listing_images_on_listing_id_and_position", unique: true
    t.index ["listing_id"], name: "index_listing_images_on_listing_id"
  end

  create_table "listings", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "closed_at"
    t.string "closed_reason"
    t.datetime "created_at", null: false
    t.bigint "created_by_tenant_member_id"
    t.text "description"
    t.datetime "last_published_at"
    t.string "listing_type", null: false
    t.datetime "published_at"
    t.string "status", default: "draft", null: false
    t.bigint "tenant_id", null: false
    t.bigint "tenant_location_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_tenant_member_id"
    t.index ["created_by_tenant_member_id"], name: "index_listings_on_created_by_tenant_member_id"
    t.index ["listing_type", "status"], name: "index_listings_on_listing_type_and_status"
    t.index ["status", "published_at"], name: "index_listings_on_status_and_published_at"
    t.index ["tenant_id"], name: "index_listings_on_tenant_id"
    t.index ["tenant_location_id"], name: "index_listings_on_tenant_location_id"
    t.index ["updated_by_tenant_member_id"], name: "index_listings_on_updated_by_tenant_member_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "stay_amenities", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category", default: "other", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", limit: 100, null: false
    t.integer "position", null: false
    t.string "scope", null: false
    t.bigint "tenant_id"
    t.datetime "updated_at", null: false
    t.index ["active", "scope", "category"], name: "index_stay_amenities_on_active_and_scope_and_category"
    t.index ["code"], name: "idx_common_stay_amenities_code", unique: true, where: "(tenant_id IS NULL)"
    t.index ["tenant_id", "code"], name: "idx_tenant_stay_amenities_code", unique: true, where: "(tenant_id IS NOT NULL)"
    t.index ["tenant_id"], name: "index_stay_amenities_on_tenant_id"
  end

  create_table "stay_bed_blocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ends_on", null: false
    t.text "notes"
    t.string "reason", null: false
    t.date "starts_on", null: false
    t.bigint "stay_bed_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stay_bed_id", "starts_on", "ends_on"], name: "index_stay_bed_blocks_on_stay_bed_id_and_starts_on_and_ends_on"
    t.index ["stay_bed_id"], name: "index_stay_bed_blocks_on_stay_bed_id"
  end

  create_table "stay_beds", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "notes"
    t.bigint "stay_room_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stay_room_id", "name"], name: "index_stay_beds_on_stay_room_id_and_name", unique: true
    t.index ["stay_room_id"], name: "index_stay_beds_on_stay_room_id"
  end

  create_table "stay_listing_amenities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "stay_amenity_id", null: false
    t.bigint "stay_listing_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stay_amenity_id"], name: "index_stay_listing_amenities_on_stay_amenity_id"
    t.index ["stay_listing_id", "stay_amenity_id"], name: "idx_stay_listing_amenities_unique", unique: true
    t.index ["stay_listing_id"], name: "index_stay_listing_amenities_on_stay_listing_id"
  end

  create_table "stay_listings", force: :cascade do |t|
    t.integer "approval_deadline_hours", default: 24, null: false
    t.integer "booking_close_hours_before", default: 0, null: false
    t.string "booking_confirmation_mode", default: "approval_required", null: false
    t.integer "booking_open_days_before", default: 365, null: false
    t.time "check_in_time"
    t.time "check_out_time"
    t.datetime "created_at", null: false
    t.text "house_rules"
    t.time "latest_check_in_time"
    t.bigint "listing_id", null: false
    t.date "stay_available_ends_on"
    t.date "stay_available_starts_on"
    t.string "time_zone", default: "Asia/Tokyo", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_stay_listings_on_listing_id", unique: true
  end

  create_table "stay_rate_plans", force: :cascade do |t|
    t.string "cancellation_policy_type", default: "standard", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "meal_type", default: "room_only", null: false
    t.string "name", limit: 100, null: false
    t.string "status", default: "draft", null: false
    t.bigint "stay_listing_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stay_listing_id", "name"], name: "index_stay_rate_plans_on_stay_listing_id_and_name", unique: true
    t.index ["stay_listing_id", "status"], name: "index_stay_rate_plans_on_stay_listing_id_and_status"
    t.index ["stay_listing_id"], name: "index_stay_rate_plans_on_stay_listing_id"
  end

  create_table "stay_room_blocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ends_on", null: false
    t.text "notes"
    t.string "reason", null: false
    t.date "starts_on", null: false
    t.bigint "stay_room_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stay_room_id", "starts_on", "ends_on"], name: "idx_on_stay_room_id_starts_on_ends_on_56279077be"
    t.index ["stay_room_id"], name: "index_stay_room_blocks_on_stay_room_id"
  end

  create_table "stay_room_type_amenities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "stay_amenity_id", null: false
    t.bigint "stay_room_type_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stay_amenity_id"], name: "index_stay_room_type_amenities_on_stay_amenity_id"
    t.index ["stay_room_type_id", "stay_amenity_id"], name: "idx_stay_room_type_amenities_unique", unique: true
    t.index ["stay_room_type_id"], name: "index_stay_room_type_amenities_on_stay_room_type_id"
  end

  create_table "stay_room_type_daily_sales_controls", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "sales_limit", null: false
    t.date "stay_date", null: false
    t.bigint "stay_room_type_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stay_room_type_id", "stay_date"], name: "idx_stay_room_type_daily_sales_unique", unique: true
    t.index ["stay_room_type_id"], name: "index_stay_room_type_daily_sales_controls_on_stay_room_type_id"
  end

  create_table "stay_room_type_rate_daily_prices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "price_amount", null: false
    t.date "stay_date", null: false
    t.bigint "stay_room_type_rate_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stay_room_type_rate_id", "stay_date"], name: "idx_stay_daily_prices_unique", unique: true
    t.index ["stay_room_type_rate_id"], name: "idx_on_stay_room_type_rate_id_b7f2c2a804"
  end

  create_table "stay_room_type_rates", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "JPY", null: false
    t.integer "price_per_night_amount", null: false
    t.bigint "stay_rate_plan_id", null: false
    t.bigint "stay_room_type_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stay_rate_plan_id"], name: "index_stay_room_type_rates_on_stay_rate_plan_id"
    t.index ["stay_room_type_id", "stay_rate_plan_id"], name: "idx_stay_room_type_rates_unique", unique: true
    t.index ["stay_room_type_id"], name: "index_stay_room_type_rates_on_stay_room_type_id"
  end

  create_table "stay_room_types", force: :cascade do |t|
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", limit: 100, null: false
    t.string "room_kind", null: false
    t.string "status", default: "draft", null: false
    t.bigint "stay_listing_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stay_listing_id", "name"], name: "index_stay_room_types_on_stay_listing_id_and_name", unique: true
    t.index ["stay_listing_id", "status"], name: "index_stay_room_types_on_stay_listing_id_and_status"
    t.index ["stay_listing_id"], name: "index_stay_room_types_on_stay_listing_id"
  end

  create_table "stay_rooms", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "notes"
    t.bigint "stay_room_type_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stay_room_type_id", "name"], name: "index_stay_rooms_on_stay_room_type_id_and_name", unique: true
    t.index ["stay_room_type_id"], name: "index_stay_rooms_on_stay_room_type_id"
  end

  create_table "tenant_locations", force: :cascade do |t|
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.datetime "created_at", null: false
    t.string "google_place_id"
    t.decimal "latitude", null: false
    t.string "location_type", default: "other", null: false
    t.decimal "longitude", null: false
    t.string "name", null: false
    t.string "postal_code"
    t.string "prefecture"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "name"], name: "index_tenant_locations_on_tenant_id_and_name", unique: true
    t.index ["tenant_id"], name: "index_tenant_locations_on_tenant_id"
  end

  create_table "tenant_members", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.string "status", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_tenant_members_on_account_id", unique: true
    t.index ["tenant_id"], name: "index_tenant_members_on_tenant_id"
    t.check_constraint "role::text = ANY (ARRAY['owner'::character varying, 'staff'::character varying]::text[])", name: "tenant_members_role_check"
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kana"
    t.string "name"
    t.bigint "primary_tenant_location_id"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["primary_tenant_location_id"], name: "index_tenants_on_primary_tenant_location_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.string "avatar_url"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.string "kana"
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_profiles_on_user_id", unique: true
  end

  create_table "user_refresh_tokens", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "device_id"
    t.string "device_name"
    t.datetime "expired_at"
    t.datetime "last_used_at"
    t.string "last_used_ip"
    t.datetime "revoked_at"
    t.string "token_digest"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["account_id"], name: "index_user_refresh_tokens_on_account_id"
    t.index ["token_digest"], name: "index_user_refresh_tokens_on_token_digest"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id", unique: true
  end

  add_foreign_key "admins", "accounts"
  add_foreign_key "favorites", "listings"
  add_foreign_key "favorites", "users"
  add_foreign_key "job_listings", "listings"
  add_foreign_key "listing_images", "listings"
  add_foreign_key "listings", "tenant_locations"
  add_foreign_key "listings", "tenant_members", column: "created_by_tenant_member_id", on_delete: :nullify
  add_foreign_key "listings", "tenant_members", column: "updated_by_tenant_member_id", on_delete: :nullify
  add_foreign_key "listings", "tenants"
  add_foreign_key "stay_amenities", "tenants"
  add_foreign_key "stay_bed_blocks", "stay_beds"
  add_foreign_key "stay_beds", "stay_rooms"
  add_foreign_key "stay_listing_amenities", "stay_amenities"
  add_foreign_key "stay_listing_amenities", "stay_listings"
  add_foreign_key "stay_listings", "listings"
  add_foreign_key "stay_rate_plans", "stay_listings"
  add_foreign_key "stay_room_blocks", "stay_rooms"
  add_foreign_key "stay_room_type_amenities", "stay_amenities"
  add_foreign_key "stay_room_type_amenities", "stay_room_types"
  add_foreign_key "stay_room_type_daily_sales_controls", "stay_room_types"
  add_foreign_key "stay_room_type_rate_daily_prices", "stay_room_type_rates"
  add_foreign_key "stay_room_type_rates", "stay_rate_plans"
  add_foreign_key "stay_room_type_rates", "stay_room_types"
  add_foreign_key "stay_room_types", "stay_listings"
  add_foreign_key "stay_rooms", "stay_room_types"
  add_foreign_key "tenant_locations", "tenants", on_delete: :cascade
  add_foreign_key "tenant_members", "accounts"
  add_foreign_key "tenant_members", "tenants"
  add_foreign_key "tenants", "tenant_locations", column: "primary_tenant_location_id"
  add_foreign_key "user_profiles", "users"
  add_foreign_key "user_refresh_tokens", "accounts"
  add_foreign_key "users", "accounts"
end
