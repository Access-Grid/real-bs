class DataLayout < ApplicationRecord
  include HasUuid

  belongs_to :data_format, class_name: "CredentialFormat", foreign_key: "data_format_id", optional: true

  validates :name, presence: true
end
