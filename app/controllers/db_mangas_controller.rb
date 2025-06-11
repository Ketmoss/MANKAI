class DbMangasController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @dbmangas = pagy(DbManga.all, items: 10)
  end

  def show
    @dbmanga = DbManga.find(params[:id])
  end

	def display_db_mangas_list
		@user_collection = UserCollection.find(params[:user_collection_id])
		@db_mangas = DbManga.all
	end

end
