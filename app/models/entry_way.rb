class EntryWay < ApplicationRecord
  belongs_to :sector
  belongs_to :access_controller

  has_many :readers, dependent: :destroy
  has_many :sensors, dependent: :destroy

  validates :name, presence: true
end
