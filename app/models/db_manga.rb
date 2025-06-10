class DbManga < ApplicationRecord

  has_many :reviews
	has_many :owned_mangas

end
