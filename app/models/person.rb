class Person < ApplicationRecord
  belongs_to :group

  has_many :credentials, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
end
