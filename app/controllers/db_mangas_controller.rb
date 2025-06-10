class DbMangasController < ApplicationController


  def index
    @dbmangas = DbManga.all
  end

  def show
    @dbmanga = DbManga.find(params[:id])
  end

	def display_db_mangas_list
		@user_collection = UserCollection.find(params[:user_collection_id])
		@db_mangas = DbManga.all
	end

end
