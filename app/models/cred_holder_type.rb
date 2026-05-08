class CredHolderType < ApplicationRecord
  include HasUuid

  has_many :people, dependent: :destroy

  validates :name, presence: true
end
