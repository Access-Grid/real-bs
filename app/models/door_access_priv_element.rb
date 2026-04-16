class DoorAccessPrivElement < ApplicationRecord
  belongs_to :access_rule_set
  belongs_to :door
end
