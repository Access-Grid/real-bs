class ScheduleElement < ApplicationRecord
  belongs_to :schedule

  has_many :schedule_element_holiday_types, dependent: :destroy
  has_many :holiday_types, through: :schedule_element_holiday_types
end
