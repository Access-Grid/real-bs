class CredentialType < ApplicationRecord
  has_many :credentials, dependent: :destroy
end
