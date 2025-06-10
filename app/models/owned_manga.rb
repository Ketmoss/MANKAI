class OwnedManga < ApplicationRecord
  belongs_to :user_collection
  belongs_to :db_manga
end
