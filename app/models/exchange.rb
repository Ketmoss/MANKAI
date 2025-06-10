class Exchange < ApplicationRecord
  belongs_to :user
  belongs_to :owned_manga
end
