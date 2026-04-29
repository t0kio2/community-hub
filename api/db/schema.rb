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

ActiveRecord::Schema[8.1].define(version: 2026_04_29_043051) do
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
    t.string "role"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_admins_on_account_id", unique: true
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
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.bigint "created_by_tenant_member_id"
    t.text "description"
    t.string "listing_type", null: false
    t.datetime "published_at"
    t.string "status", default: "draft", null: false
    t.bigint "tenant_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_tenant_member_id"
    t.index ["created_by_tenant_member_id"], name: "index_listings_on_created_by_tenant_member_id"
    t.index ["listing_type", "status"], name: "index_listings_on_listing_type_and_status"
    t.index ["status", "published_at"], name: "index_listings_on_status_and_published_at"
    t.index ["tenant_id"], name: "index_listings_on_tenant_id"
    t.index ["updated_by_tenant_member_id"], name: "index_listings_on_updated_by_tenant_member_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "avatar_url"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.string "kana"
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_profiles_on_account_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "stay_listings", force: :cascade do |t|
    t.string "address"
    t.text "amenities"
    t.date "available_from"
    t.date "available_until"
    t.integer "capacity"
    t.time "check_in_time"
    t.time "check_out_time"
    t.datetime "created_at", null: false
    t.text "house_rules"
    t.bigint "listing_id", null: false
    t.integer "price_per_night"
    t.string "stay_type"
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_stay_listings_on_listing_id", unique: true
  end

  create_table "tenant_members", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "role"
    t.string "status"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_tenant_members_on_account_id", unique: true
    t.index ["tenant_id"], name: "index_tenant_members_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "kana"
    t.string "name"
    t.string "status"
    t.datetime "updated_at", null: false
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
  add_foreign_key "listings", "tenant_members", column: "created_by_tenant_member_id"
  add_foreign_key "listings", "tenant_members", column: "updated_by_tenant_member_id"
  add_foreign_key "listings", "tenants"
  add_foreign_key "profiles", "accounts"
  add_foreign_key "stay_listings", "listings"
  add_foreign_key "tenant_members", "accounts"
  add_foreign_key "tenant_members", "tenants"
  add_foreign_key "user_refresh_tokens", "accounts"
  add_foreign_key "users", "accounts"
end
