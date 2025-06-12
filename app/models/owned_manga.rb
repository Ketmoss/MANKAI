class OwnedManga < ApplicationRecord
  belongs_to :user_collection
  belongs_to :db_manga

  validates :db_manga_id, uniqueness: { scope: :user_collection_id,
                                       message: "est déjà dans cette collection" }
  validates :volume, presence: true, numericality: { greater_than: 0 }
  validates :condition, presence: true
end
