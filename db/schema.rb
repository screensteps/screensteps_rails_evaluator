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

ActiveRecord::Schema[8.1].define(version: 2026_06_19_150043) do
  create_table "accounts", force: :cascade do |t|
    t.datetime "activated_at", precision: nil
    t.boolean "api_enabled", default: false, null: false
    t.string "api_key", limit: 16
    t.datetime "canceled_at", precision: nil
    t.string "company"
    t.integer "company_space_id"
    t.datetime "created_at", null: false
    t.json "data"
    t.string "date_format"
    t.string "domain"
    t.boolean "flagged_for_deletion", default: false, null: false
    t.datetime "last_login", precision: nil
    t.integer "owner_id"
    t.string "public_id", limit: 40
    t.date "scheduled_deletion_at"
    t.string "status", default: "inactive"
    t.string "time_format"
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_accounts_on_api_key", unique: true
    t.index ["domain"], name: "index_accounts_on_domain"
    t.index ["public_id"], name: "index_accounts_on_public_id", unique: true
    t.index ["status"], name: "index_accounts_on_status"
  end

  create_table "manuals", force: :cascade do |t|
    t.boolean "allow_comments", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "creator_id"
    t.datetime "discarded_at", precision: nil
    t.boolean "draft", default: false, null: false
    t.string "icon", default: "book"
    t.boolean "internal", default: false, null: false
    t.text "message"
    t.string "meta_description"
    t.string "meta_title"
    t.string "permalink", limit: 50
    t.string "public_title"
    t.boolean "restricted", default: false, null: false
    t.integer "space_id", null: false
    t.string "title"
    t.string "toc_description"
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.boolean "visible", default: false, null: false
    t.index ["creator_id"], name: "index_manuals_on_creator_id"
    t.index ["restricted"], name: "index_manuals_on_restricted"
    t.index ["space_id", "internal", "permalink"], name: "index_manuals_on_space_id_and_internal_and_permalink"
    t.index ["space_id"], name: "index_manuals_on_space_id"
    t.index ["uuid"], name: "index_manuals_on_uuid", unique: true
  end

  create_table "spaces", force: :cascade do |t|
    t.integer "account_id"
    t.boolean "allow_ratings", default: false, null: false
    t.datetime "created_at", null: false
    t.json "data"
    t.text "description"
    t.string "domain"
    t.boolean "hide_from_list", default: false, null: false
    t.string "host_mapping"
    t.string "language", limit: 10, default: "en", null: false
    t.text "message"
    t.string "meta_description"
    t.string "meta_title"
    t.string "permalink", limit: 50
    t.boolean "protected", default: true, null: false
    t.string "theme", default: "alpha", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_spaces_on_account_id"
    t.index ["host_mapping"], name: "index_spaces_on_host_mapping", unique: true
    t.index ["language"], name: "index_spaces_on_language"
    t.index ["permalink", "account_id"], name: "index_spaces_on_permalink_and_account_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.integer "account_id"
    t.datetime "activated_at", precision: nil
    t.datetime "created_at", null: false
    t.json "data"
    t.boolean "deactivated", default: false, null: false
    t.datetime "discarded_at"
    t.string "email"
    t.string "encrypted_password", default: ""
    t.string "first_name"
    t.boolean "invite_pending", default: false, null: false
    t.datetime "last_login", precision: nil
    t.string "last_name"
    t.string "login"
    t.virtual "name", type: :string, as: "(case when first_name is not null and last_name is not null then first_name || ' ' || last_name else coalesce(first_name, last_name, login) end)", stored: true
    t.string "public_id"
    t.string "role"
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.index ["account_id", "last_name", "first_name"], name: "index_users_on_account_id_and_last_name_and_first_name"
    t.index ["account_id", "role"], name: "index_users_on_account_id_and_role"
    t.index ["discarded_at", "deactivated", "invite_pending", "account_id"], name: "idx_on_discarded_at_deactivated_invite_pending_acco_aedfff371e"
    t.index ["email", "account_id"], name: "index_users_on_email_and_account_id", unique: true
    t.index ["login", "account_id"], name: "index_users_on_login_and_account_id", unique: true
    t.index ["public_id"], name: "index_users_on_public_id", unique: true
    t.index ["role", "discarded_at", "deactivated", "invite_pending", "account_id"], name: "idx_on_role_discarded_at_deactivated_invite_pending_429ed373a3"
  end
end
