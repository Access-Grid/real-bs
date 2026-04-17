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

ActiveRecord::Schema[8.0].define(version: 2026_04_17_000001) do
  create_table "access_paths", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "access_rule_sets", force: :cascade do |t|
    t.string "name"
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.integer "priv_type", default: 0
    t.boolean "enabled", default: true
    t.string "external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_access_rule_sets_on_uuid", unique: true
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

  create_table "cred_holder_types", force: :cascade do |t|
    t.string "name"
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_cred_holder_types_on_uuid", unique: true
  end

  create_table "cred_priv_bindings", force: :cascade do |t|
    t.integer "credential_id", null: false
    t.integer "access_rule_set_id"
    t.integer "dev_as_door_access_priv_unid"
    t.boolean "sched_restriction_invert", default: false
    t.integer "schedule_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_rule_set_id"], name: "index_cred_priv_bindings_on_access_rule_set_id"
    t.index ["credential_id"], name: "index_cred_priv_bindings_on_credential_id"
    t.index ["schedule_id"], name: "index_cred_priv_bindings_on_schedule_id"
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
    t.index ["credential_format_parity_bit_id"], name: "idx_on_credential_format_parity_bit_id_dc279530a1"
  end

  create_table "credential_format_parity_bits", force: :cascade do |t|
    t.string "kind"
    t.string "index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "credential_formats", force: :cascade do |t|
    t.string "name"
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.integer "length"
    t.integer "data_format_type", default: 1
    t.integer "min_bits"
    t.integer "max_bits"
    t.boolean "support_reverse_read", default: false
    t.json "elements"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_credential_formats_on_uuid", unique: true
  end

  create_table "credential_types", force: :cascade do |t|
    t.string "name"
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.integer "priority"
    t.json "card_pin_template"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_credential_types_on_uuid", unique: true
  end

  create_table "credentials", force: :cascade do |t|
    t.string "name"
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.integer "person_id"
    t.integer "credential_type_id"
    t.boolean "enabled", default: true
    t.datetime "effective"
    t.datetime "expires"
    t.json "card_pin"
    t.json "door_access_modifiers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credential_type_id"], name: "index_credentials_on_credential_type_id"
    t.index ["person_id"], name: "index_credentials_on_person_id"
    t.index ["uuid"], name: "index_credentials_on_uuid", unique: true
  end

  create_table "data_layouts", force: :cascade do |t|
    t.string "name"
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.integer "layout_type", default: 0
    t.integer "priority"
    t.boolean "enabled", default: true
    t.integer "data_format_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_data_layouts_on_uuid", unique: true
  end

  create_table "devices", force: :cascade do |t|
    t.string "type", null: false
    t.string "name"
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.boolean "enabled", default: true
    t.integer "comm_family"
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
    t.string "external_id"
    t.string "address"
    t.integer "logical_address"
    t.string "mac_address"
    t.integer "port"
    t.integer "speed"
    t.integer "dev_sub_type"
    t.integer "dev_mod"
    t.integer "dev_platform"
    t.integer "dev_use"
    t.string "time_zone"
    t.boolean "ignore_daylight_savings", default: false
    t.json "dev_mod_config"
    t.json "dev_config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_dev_mod_text"
    t.string "external_dev_mod_id"
    t.index ["logical_parent_id"], name: "index_devices_on_logical_parent_id"
    t.index ["physical_parent_id"], name: "index_devices_on_physical_parent_id"
    t.index ["sector_id"], name: "index_devices_on_sector_id"
    t.index ["type"], name: "index_devices_on_type"
    t.index ["uuid"], name: "index_devices_on_uuid", unique: true
  end

  create_table "door_access_priv_elements", force: :cascade do |t|
    t.integer "access_rule_set_id", null: false
    t.integer "door_id", null: false
    t.boolean "sched_restriction_invert", default: false
    t.integer "schedule_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_rule_set_id"], name: "index_door_access_priv_elements_on_access_rule_set_id"
    t.index ["schedule_id"], name: "index_door_access_priv_elements_on_schedule_id"
  end

  create_table "encryption_keys", force: :cascade do |t|
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.string "algorithm"
    t.integer "size"
    t.string "key_identifier"
    t.text "bytes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_encryption_keys_on_uuid", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.datetime "hw_time"
    t.datetime "db_time"
    t.string "hw_time_zone"
    t.integer "evt_code"
    t.string "external_evt_code_text"
    t.string "external_evt_code_id"
    t.integer "evt_sub_code"
    t.string "external_sub_code_text"
    t.string "external_sub_code_id"
    t.integer "priority"
    t.string "data"
    t.boolean "consumed", default: false
    t.json "evt_modifiers"
    t.json "evt_dev_ref"
    t.json "evt_controller_ref"
    t.json "evt_cred_ref"
    t.json "evt_sched_ref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["evt_code"], name: "index_events_on_evt_code"
    t.index ["hw_time"], name: "index_events_on_hw_time"
    t.index ["uuid"], name: "index_events_on_uuid", unique: true
  end

  create_table "holiday_calendars", force: :cascade do |t|
    t.string "name", null: false
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_holiday_calendars_on_uuid", unique: true
  end

  create_table "holiday_holiday_types", force: :cascade do |t|
    t.integer "holiday_id", null: false
    t.integer "holiday_type_id", null: false
    t.index ["holiday_id", "holiday_type_id"], name: "idx_hol_hol_types_unique", unique: true
    t.index ["holiday_id"], name: "index_holiday_holiday_types_on_holiday_id"
    t.index ["holiday_type_id"], name: "index_holiday_holiday_types_on_holiday_type_id"
  end

  create_table "holiday_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.string "external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_holiday_types_on_uuid", unique: true
  end

  create_table "holidays", force: :cascade do |t|
    t.string "name", null: false
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.integer "holiday_calendar_id"
    t.date "date"
    t.integer "num_days", default: 1
    t.boolean "repeat", default: false
    t.integer "num_years_repeat", default: 0
    t.boolean "preserve_sched_day", default: false
    t.boolean "all_hol_types", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["holiday_calendar_id"], name: "index_holidays_on_holiday_calendar_id"
    t.index ["uuid"], name: "index_holidays_on_uuid", unique: true
  end

  create_table "people", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "title"
    t.string "phone_number"
    t.string "email"
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.boolean "enabled", default: true
    t.integer "cred_holder_type_id"
    t.string "custom_text_0"
    t.string "custom_text_1"
    t.string "custom_text_2"
    t.string "custom_text_3"
    t.string "custom_text_4"
    t.string "custom_text_5"
    t.string "custom_text_6"
    t.string "custom_text_7"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cred_holder_type_id"], name: "index_people_on_cred_holder_type_id"
    t.index ["uuid"], name: "index_people_on_uuid", unique: true
  end

  create_table "schedule_element_holiday_types", force: :cascade do |t|
    t.integer "schedule_element_id", null: false
    t.integer "holiday_type_id", null: false
    t.index ["holiday_type_id"], name: "index_schedule_element_holiday_types_on_holiday_type_id"
    t.index ["schedule_element_id", "holiday_type_id"], name: "idx_sched_elem_hol_types_unique", unique: true
    t.index ["schedule_element_id"], name: "index_schedule_element_holiday_types_on_schedule_element_id"
  end

  create_table "schedule_elements", force: :cascade do |t|
    t.integer "schedule_id", null: false
    t.boolean "holidays", default: false
    t.boolean "mon", default: false
    t.boolean "tues", default: false
    t.boolean "wed", default: false
    t.boolean "thur", default: false
    t.boolean "fri", default: false
    t.boolean "sat", default: false
    t.boolean "sun", default: false
    t.string "start_time"
    t.string "stop_time"
    t.integer "plus_days", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["schedule_id"], name: "index_schedule_elements_on_schedule_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.string "name", null: false
    t.string "uuid"
    t.integer "lock_version", default: 0
    t.string "tag"
    t.string "external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_schedules_on_uuid", unique: true
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
  add_foreign_key "cred_priv_bindings", "access_rule_sets"
  add_foreign_key "cred_priv_bindings", "credentials"
  add_foreign_key "cred_priv_bindings", "schedules"
  add_foreign_key "credential_format_field_bits", "credential_format_fields"
  add_foreign_key "credential_format_parity_bit_ranges", "credential_format_parity_bits"
  add_foreign_key "credentials", "credential_types"
  add_foreign_key "credentials", "people"
  add_foreign_key "data_layouts", "credential_formats", column: "data_format_id"
  add_foreign_key "devices", "devices", column: "logical_parent_id"
  add_foreign_key "devices", "devices", column: "physical_parent_id"
  add_foreign_key "devices", "sectors"
  add_foreign_key "door_access_priv_elements", "access_rule_sets"
  add_foreign_key "door_access_priv_elements", "devices", column: "door_id"
  add_foreign_key "door_access_priv_elements", "schedules"
  add_foreign_key "holiday_holiday_types", "holiday_types"
  add_foreign_key "holiday_holiday_types", "holidays"
  add_foreign_key "holidays", "holiday_calendars"
  add_foreign_key "people", "cred_holder_types"
  add_foreign_key "schedule_element_holiday_types", "holiday_types"
  add_foreign_key "schedule_element_holiday_types", "schedule_elements"
  add_foreign_key "schedule_elements", "schedules"
  add_foreign_key "sectors", "buildings"
  add_foreign_key "sectors", "sectors", column: "parent_id"
end
