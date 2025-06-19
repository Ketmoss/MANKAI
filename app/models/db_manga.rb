class DbManga < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :search_manga,
    against: { genre: 'A', title: 'B', synopsis: 'C', author: 'D' },
    using: {
      tsearch:  { prefix: true, dictionary: 'french' },
      trigram:  { threshold: 0.25 }
    }

  has_many :reviews
	has_many :owned_mangas

end
