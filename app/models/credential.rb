class Credential < ApplicationRecord
  include HasUuid

  belongs_to :person, optional: true
  belongs_to :credential_type, optional: true
  has_many :cred_priv_bindings, dependent: :destroy

  validates :name, presence: true
end
