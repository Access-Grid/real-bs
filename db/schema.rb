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

ActiveRecord::Schema[8.0].define(version: 2026_04_16_180343) do
  create_table "access_paths", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "access_rule_sets", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "api_sessions", force: :cascade do |t|
    t.string "session_token", null: false
    t.integer "user_id", null: false
    t.datetime "expires_at", null: false
    t.integer "api_client_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_token"], name: "index_api_sessions_on_session_token", unique: true
    t.index ["user_id"], name: "index_api_sessions_on_user_id"
  end

  create_table "buildings", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.string "address_2"
    t.string "city"
    t.string "region"
    t.string "country"
    t.string "postal_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "credential_format_field_bits", force: :cascade do |t|
    t.integer "index"
    t.integer "credential_format_field_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credential_format_field_id"], name: "idx_on_credential_format_field_id_fb5865f3a1"
  end

  create_table "credential_format_fields", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "credential_format_parity_bit_ranges", force: :cascade do |t|
    t.integer "credential_format_parity_bit_id", null: false
    t.integer "index"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credential_format_parity_bit_id"], name: "idx_on_credential_format_parity_bit_id_aed47f38e7"
  end

  create_table "credential_format_parity_bits", force: :cascade do |t|
    t.string "kind"
    t.string "index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "credential_formats", force: :cascade do |t|
    t.string "name"
    t.integer "length"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "credential_types", force: :cascade do |t|
    t.string "kind"
    t.string "frequency"
    t.string "protocol"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "credentials", force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "credential_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credential_type_id"], name: "index_credentials_on_credential_type_id"
    t.index ["person_id"], name: "index_credentials_on_person_id"
  end

  create_table "devices", force: :cascade do |t|
    t.string "type", null: false
    t.string "name"
    t.string "uuid"
    t.boolean "enabled", default: true
    t.integer "sector_id"
    t.integer "physical_parent_id"
    t.integer "logical_parent_id"
    t.string "brand"
    t.string "model"
    t.string "serial_number"
    t.boolean "is_virtual"
    t.string "last_known_state"
    t.datetime "last_state_update"
    t.json "metadata"
    t.json "public_metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["logical_parent_id"], name: "index_devices_on_logical_parent_id"
    t.index ["physical_parent_id"], name: "index_devices_on_physical_parent_id"
    t.index ["sector_id"], name: "index_devices_on_sector_id"
    t.index ["type"], name: "index_devices_on_type"
    t.index ["uuid"], name: "index_devices_on_uuid", unique: true
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "people", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "title"
    t.string "phone_number"
    t.string "email"
    t.integer "group_id", null: false
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_people_on_group_id"
  end

  create_table "sectors", force: :cascade do |t|
    t.string "name"
    t.integer "building_id", null: false
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["building_id"], name: "index_sectors_on_building_id"
    t.index ["parent_id"], name: "index_sectors_on_parent_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "api_sessions", "users"
  add_foreign_key "credential_format_field_bits", "credential_format_fields"
  add_foreign_key "credential_format_parity_bit_ranges", "credential_format_parity_bits"
  add_foreign_key "credentials", "credential_types"
  add_foreign_key "credentials", "people"
  add_foreign_key "devices", "devices", column: "logical_parent_id"
  add_foreign_key "devices", "devices", column: "physical_parent_id"
  add_foreign_key "devices", "sectors"
  add_foreign_key "people", "groups"
  add_foreign_key "sectors", "buildings"
  add_foreign_key "sectors", "sectors", column: "parent_id"
end
