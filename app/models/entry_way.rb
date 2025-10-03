class EntryWay < ApplicationRecord
  belongs_to :sector
  belongs_to :access_controller
end
