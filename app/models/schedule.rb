class Schedule < ApplicationRecord
  include HasUuid

  has_many :schedule_elements, dependent: :destroy
  has_many :door_access_priv_elements, dependent: :nullify

  validates :name, presence: true
end
