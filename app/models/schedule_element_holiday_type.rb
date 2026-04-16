class ScheduleElementHolidayType < ApplicationRecord
  belongs_to :schedule_element
  belongs_to :holiday_type
end
