class AccessController < ApplicationRecord
  include HasUuid

  belongs_to :sector

  has_many :entry_ways, dependent: :destroy
  has_many :readers, dependent: :destroy
  has_many :sensors, dependent: :destroy

  validates :name, presence: true
end
