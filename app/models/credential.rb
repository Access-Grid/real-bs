class Credential < ApplicationRecord
  include HasUuid

  belongs_to :person, optional: true
  belongs_to :credential_type, optional: true

  validates :name, presence: true
end
