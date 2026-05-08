class AccessRuleSet < ApplicationRecord
  include HasUuid

  has_many :door_access_priv_elements, dependent: :destroy

  validates :name, presence: true
end
