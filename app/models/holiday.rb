class Holiday < ApplicationRecord
  include HasUuid

  belongs_to :holiday_calendar, optional: true

  has_many :holiday_holiday_types, dependent: :destroy
  has_many :holiday_types, through: :holiday_holiday_types

  validates :name, presence: true
end
