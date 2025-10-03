class Sensor < ApplicationRecord
  belongs_to :access_controller
  belongs_to :entry_way
end
