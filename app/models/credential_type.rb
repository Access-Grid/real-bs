class CredentialType < ApplicationRecord
  include HasUuid

  has_many :credentials, dependent: :destroy

  validates :name, presence: true
end
