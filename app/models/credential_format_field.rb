class CredentialFormatField < ApplicationRecord
  has_many :credential_format_field_bits, dependent: :destroy
end
