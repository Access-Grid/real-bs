class HolidayType < ApplicationRecord
  include HasUuid

  has_many :schedule_element_holiday_types, dependent: :destroy
  has_many :holiday_holiday_types, dependent: :destroy

  validates :name, presence: true
end
