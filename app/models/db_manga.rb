class DbManga < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :search_manga,
    against: { synopsis: 'A', genre: 'B', title: 'C', author: 'D' },
    using: {
      tsearch:  { prefix: true, dictionary: 'french' },
      trigram:  { threshold: 0.3 }
    }

  has_many :reviews
	has_many :owned_mangas

end
