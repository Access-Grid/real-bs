class Sector < ApplicationRecord
  belongs_to :building
  belongs_to :parent, class_name: "Sector", optional: true

  has_many :children, class_name: "Sector", foreign_key: "parent_id", dependent: :nullify
  has_many :access_controllers, dependent: :destroy
  has_many :entry_ways, dependent: :destroy

  validates :name, presence: true
end
