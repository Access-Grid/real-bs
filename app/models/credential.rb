class Credential < ApplicationRecord
  belongs_to :person
  belongs_to :credential_type
end
