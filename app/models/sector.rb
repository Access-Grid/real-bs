class Sector < ApplicationRecord
  belongs_to :building
  belongs_to :parent
end
