class Device < ApplicationRecord
  include HasUuid

  belongs_to :sector, optional: true
  belongs_to :physical_parent, class_name: "Device", optional: true
  belongs_to :logical_parent, class_name: "Device", optional: true

  has_many :physical_children, class_name: "Device", foreign_key: "physical_parent_id", dependent: :nullify
  has_many :logical_children, class_name: "Device", foreign_key: "logical_parent_id", dependent: :nullify

  validates :name, presence: true

  # Flex API devType mapping
  DEV_TYPES = {
    "NodeDev" => 0,
    "IoController" => 1,
    "Sensor" => 2,
    "Actuator" => 3,
    "CredReader" => 4,
    "Door" => 5
  }.freeze

  def dev_type
    DEV_TYPES[type] || -1
  end
end
