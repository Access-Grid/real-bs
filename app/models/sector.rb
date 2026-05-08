class Sector < ApplicationRecord
  belongs_to :building
  belongs_to :parent, class_name: "Sector", optional: true

  has_many :children, class_name: "Sector", foreign_key: "parent_id", dependent: :nullify
  has_many :devices, dependent: :destroy

  validates :name, presence: true
end
