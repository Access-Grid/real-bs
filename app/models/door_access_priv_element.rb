class DoorAccessPrivElement < ApplicationRecord
  belongs_to :access_rule_set
  belongs_to :door
  belongs_to :schedule, optional: true
end
