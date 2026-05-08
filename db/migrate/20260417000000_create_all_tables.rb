class CreateAllTables < ActiveRecord::Migration[8.0]
  def change
    create_table "access_paths" do |t|
      t.string "name"
      t.timestamps
    end

    create_table "buildings" do |t|
      t.string "name"
      t.string "address"
      t.string "address_2"
      t.string "city"
      t.string "region"
      t.string "country"
      t.string "postal_code"
      t.timestamps
    end

    create_table "sectors" do |t|
      t.string "name"
      t.references :building, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :sectors }
      t.timestamps
    end

    create_table "cred_holder_types" do |t|
      t.string "name"
      t.string "uuid"
      t.integer "lock_version", default: 0
      t.string "tag"
      t.timestamps
      t.index ["uuid"], unique: true
    end

    create_table "people" do |t|
      t.string "first_name"
      t.string "last_name"
      t.string "title"
      t.string "phone_number"
      t.string "email"
      t.string "uuid"
      t.integer "lock_version", default: 0
      t.string "tag"
      t.boolean "enabled", default: true
      t.references :cred_holder_type, foreign_key: true
      t.string "custom_text_0"
      t.string "custom_text_1"
      t.string "custom_text_2"
      t.string "custom_text_3"
      t.string "custom_text_4"
      t.string "custom_text_5"
      t.string "custom_text_6"
      t.string "custom_text_7"
      t.timestamps
      t.index ["uuid"], unique: true
    end

    create_table "users" do |t|
      t.string "username", null: false
      t.string "password_digest", null: false
      t.timestamps
      t.index ["username"], unique: true
    end

    create_table "api_sessions" do |t|
      t.string "session_token", null: false
      t.references :user, null: false, foreign_key: true
      t.datetime "expires_at", null: false
      t.integer "api_client_type"
      t.timestamps
      t.index ["session_token"], unique: true
    end

    create_table "devices" do |t|
      t.string "type", null: false
      t.string "name"
      t.string "uuid"
      t.integer "lock_version", default: 0
      t.string "tag"
      t.boolean "enabled", default: true
      t.integer "comm_family"
      t.references :sector, foreign_key: true
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
      t.timestamps
      t.index ["type"]
      t.index ["uuid"], unique: true
      t.index ["physical_parent_id"]
      t.index ["logical_parent_id"]
    end

    add_foreign_key "devices", "devices", column: "physical_parent_id"
    add_foreign_key "devices", "devices", column: "logical_parent_id"

    create_table "credential_formats" do |t|
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
      t.timestamps
      t.index ["uuid"], unique: true
    end

    create_table "credential_format_fields" do |t|
      t.string "name"
      t.timestamps
    end

    create_table "credential_format_field_bits" do |t|
      t.integer "index"
      t.references :credential_format_field, null: false, foreign_key: true
      t.integer "position"
      t.timestamps
    end

    create_table "credential_format_parity_bits" do |t|
      t.string "kind"
      t.string "index"
      t.timestamps
    end

    create_table "credential_format_parity_bit_ranges" do |t|
      t.references :credential_format_parity_bit, null: false, foreign_key: true
      t.integer "index"
      t.integer "position"
      t.timestamps
    end

    create_table "credential_types" do |t|
      t.string "name"
      t.string "uuid"
      t.integer "lock_version", default: 0
      t.string "tag"
      t.integer "priority"
      t.json "card_pin_template"
      t.timestamps
      t.index ["uuid"], unique: true
    end

    create_table "credentials" do |t|
      t.string "name"
      t.string "uuid"
      t.integer "lock_version", default: 0
      t.string "tag"
      t.references :person, foreign_key: true
      t.references :credential_type, foreign_key: true
      t.boolean "enabled", default: true
      t.datetime "effective"
      t.datetime "expires"
      t.json "card_pin"
      t.json "door_access_modifiers"
      t.timestamps
      t.index ["uuid"], unique: true
    end

    create_table "data_layouts" do |t|
      t.string "name"
      t.string "uuid"
      t.integer "lock_version", default: 0
      t.string "tag"
      t.integer "layout_type", default: 0
      t.integer "priority"
      t.boolean "enabled", default: true
      t.integer "data_format_id"
      t.timestamps
      t.index ["uuid"], unique: true
    end

    add_foreign_key "data_layouts", "credential_formats", column: "data_format_id"

    create_table "access_rule_sets" do |t|
      t.string "name"
      t.string "uuid"
      t.integer "lock_version", default: 0
      t.string "tag"
      t.integer "priv_type", default: 0
      t.boolean "enabled", default: true
      t.string "external_id"
      t.timestamps
      t.index ["uuid"], unique: true
    end

    create_table "schedules" do |t|
      t.string "name", null: false
      t.string "uuid"
      t.integer "lock_version", default: 0
      t.string "tag"
      t.string "external_id"
      t.timestamps
      t.index ["uuid"], unique: true
    end

    create_table "schedule_elements" do |t|
      t.references :schedule, null: false, foreign_key: true
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
      t.timestamps
    end

    create_table "holiday_types" do |t|
      t.string "name", null: false
      t.string "uuid"
      t.integer "lock_version", default: 0
      t.string "tag"
      t.string "external_id"
      t.timestamps
      t.index ["uuid"], unique: true
    end

    create_table "schedule_element_holiday_types" do |t|
      t.references :schedule_element, null: false, foreign_key: true
      t.references :holiday_type, null: false, foreign_key: true
      t.index ["schedule_element_id", "holiday_type_id"], name: "idx_sched_elem_hol_types_unique", unique: true
    end

    create_table "holiday_calendars" do |t|
      t.string "name", null: false
      t.string "uuid"
      t.integer "lock_version", default: 0
      t.string "tag"
      t.timestamps
      t.index ["uuid"], unique: true
    end

    create_table "holidays" do |t|
      t.string "name", null: false
      t.string "uuid"
      t.integer "lock_version", default: 0
      t.string "tag"
      t.references :holiday_calendar, foreign_key: true
      t.date "date"
      t.integer "num_days", default: 1
      t.boolean "repeat", default: false
      t.integer "num_years_repeat", default: 0
      t.boolean "preserve_sched_day", default: false
      t.boolean "all_hol_types", default: false
      t.timestamps
      t.index ["uuid"], unique: true
    end

    create_table "holiday_holiday_types" do |t|
      t.references :holiday, null: false, foreign_key: true
      t.references :holiday_type, null: false, foreign_key: true
      t.index ["holiday_id", "holiday_type_id"], name: "idx_hol_hol_types_unique", unique: true
    end

    create_table "door_access_priv_elements" do |t|
      t.references :access_rule_set, null: false, foreign_key: true
      t.integer "door_id", null: false
      t.boolean "sched_restriction_invert", default: false
      t.references :schedule, foreign_key: true
      t.timestamps
    end

    add_foreign_key "door_access_priv_elements", "devices", column: "door_id"

    create_table "cred_priv_bindings" do |t|
      t.references :credential, null: false, foreign_key: true
      t.references :access_rule_set, foreign_key: true
      t.integer "dev_as_door_access_priv_unid"
      t.boolean "sched_restriction_invert", default: false
      t.references :schedule, foreign_key: true
      t.timestamps
    end

    create_table "events" do |t|
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
      t.timestamps
      t.index ["uuid"], unique: true
      t.index ["evt_code"]
      t.index ["hw_time"]
    end

    create_table "encryption_keys" do |t|
      t.string "uuid"
      t.integer "lock_version", default: 0
      t.string "tag"
      t.string "algorithm"
      t.integer "size"
      t.string "key_identifier"
      t.text "bytes"
      t.timestamps
      t.index ["uuid"], unique: true
    end
  end
end
