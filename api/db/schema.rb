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

ActiveRecord::Schema[8.1].define(version: 2026_04_17_030129) do
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

  create_table "jwt_denylists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp"
    t.string "jti"
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
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

  create_table "tenant_users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "role"
    t.string "status"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_tenant_users_on_account_id", unique: true
    t.index ["tenant_id"], name: "index_tenant_users_on_tenant_id"
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
  add_foreign_key "profiles", "accounts"
  add_foreign_key "tenant_users", "accounts"
  add_foreign_key "tenant_users", "tenants"
  add_foreign_key "user_refresh_tokens", "accounts"
  add_foreign_key "users", "accounts"
end
