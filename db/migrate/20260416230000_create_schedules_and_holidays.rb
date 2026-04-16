class CreateSchedulesAndHolidays < ActiveRecord::Migration[8.0]
  def change
    create_table :schedules do |t|
      t.string :name, null: false
      t.string :uuid
      t.string :external_id
      t.timestamps
    end
    add_index :schedules, :uuid, unique: true

    create_table :schedule_elements do |t|
      t.references :schedule, null: false, foreign_key: true
      t.boolean :holidays, default: false
      t.boolean :mon, default: false
      t.boolean :tues, default: false
      t.boolean :wed, default: false
      t.boolean :thur, default: false
      t.boolean :fri, default: false
      t.boolean :sat, default: false
      t.boolean :sun, default: false
      t.string :start_time
      t.string :stop_time
      t.integer :plus_days, default: 0
      t.timestamps
    end

    create_table :holiday_types do |t|
      t.string :name, null: false
      t.string :uuid
      t.string :external_id
      t.timestamps
    end
    add_index :holiday_types, :uuid, unique: true

    create_table :schedule_element_holiday_types do |t|
      t.references :schedule_element, null: false, foreign_key: true
      t.references :holiday_type, null: false, foreign_key: true
    end
    add_index :schedule_element_holiday_types,
              [:schedule_element_id, :holiday_type_id],
              unique: true, name: "idx_sched_elem_hol_types_unique"

    create_table :holiday_calendars do |t|
      t.string :name, null: false
      t.string :uuid
      t.timestamps
    end
    add_index :holiday_calendars, :uuid, unique: true

    create_table :holidays do |t|
      t.string :name, null: false
      t.string :uuid
      t.references :holiday_calendar, foreign_key: true
      t.date :date
      t.integer :num_days, default: 1
      t.boolean :repeat, default: false
      t.integer :num_years_repeat, default: 0
      t.boolean :preserve_sched_day, default: false
      t.boolean :all_hol_types, default: false
      t.timestamps
    end
    add_index :holidays, :uuid, unique: true

    create_table :holiday_holiday_types do |t|
      t.references :holiday, null: false, foreign_key: true
      t.references :holiday_type, null: false, foreign_key: true
    end
    add_index :holiday_holiday_types,
              [:holiday_id, :holiday_type_id],
              unique: true, name: "idx_hol_hol_types_unique"

    add_reference :door_access_priv_elements, :schedule,
                  foreign_key: { to_table: :schedules }, null: true
  end
end
