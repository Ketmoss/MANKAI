class Review < ApplicationRecord
  belongs_to :db_manga
  belongs_to :user
end
