class HolidayCalendar < ApplicationRecord
  include HasUuid

  has_many :holidays, dependent: :destroy

  validates :name, presence: true
end
