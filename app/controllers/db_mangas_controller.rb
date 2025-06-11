class DbMangasController < ApplicationController



  def index
    @dbmangas = DbManga.all
    if params[:query].present?
      if params[:query].present?
      sql_subquery = "title ILIKE :query OR genre ILIKE :query OR author ILIKE :query"
      @dbmangas = @dbmangas.where(sql_subquery, query: "%#{params[:query]}%")
      end
    end
  end


  def show
    @dbmanga = DbManga.find(params[:id])
  end

	def display_db_mangas_list
		@user_collection = UserCollection.find(params[:user_collection_id])
		@db_mangas = DbManga.all
	end
end
