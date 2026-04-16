class Reader < ApplicationRecord
  include HasUuid

  belongs_to :access_controller
  belongs_to :entry_way

  validates :name, presence: true
end
