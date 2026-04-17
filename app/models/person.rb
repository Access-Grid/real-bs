class Person < ApplicationRecord
  include HasUuid

  belongs_to :cred_holder_type, optional: true
  has_many :credentials, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
end
