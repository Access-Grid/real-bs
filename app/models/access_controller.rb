class AccessController < ApplicationRecord
  belongs_to :sector

  has_many :entry_ways, dependent: :destroy
  has_many :readers, dependent: :destroy
  has_many :sensors, dependent: :destroy

  validates :name, presence: true
  validates :uuid, uniqueness: true, allow_nil: true

  before_create :generate_uuid

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
