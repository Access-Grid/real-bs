class Building < ApplicationRecord
  has_many :sectors, dependent: :destroy

  validates :name, presence: true
end
