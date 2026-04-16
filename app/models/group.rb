class Group < ApplicationRecord
  has_many :people, dependent: :destroy

  validates :name, presence: true
end
