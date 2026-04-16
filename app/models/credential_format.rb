class CredentialFormat < ApplicationRecord
  include HasUuid

  has_many :data_layouts, foreign_key: :data_format_id, dependent: :nullify

  validates :name, presence: true
end
