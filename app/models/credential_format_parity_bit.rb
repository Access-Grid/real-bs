class CredentialFormatParityBit < ApplicationRecord
  has_many :credential_format_parity_bit_ranges, dependent: :destroy
end
