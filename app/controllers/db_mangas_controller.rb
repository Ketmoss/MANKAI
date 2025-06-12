class DbMangasController < ApplicationController
  include Pagy::Backend


  def index
    @pagy, @dbmangas = pagy(DbManga.all, items: 10)
    @dbmangas = DbManga.all
    if params[:query].present?
      if params[:query].present?
      sql_subquery = "title ILIKE :query OR genre ILIKE :query OR author ILIKE :query"
      @dbmangas = @dbmangas.where(sql_subquery, query: "%#{params[:query]}%")
      end
    end
  end


  def show
    @db_manga = DbManga.find(params[:id])
  end

	def display_db_mangas_list
		@user_collection = UserCollection.find(params[:user_collection_id])
		@db_mangas = DbManga.all
	end

  def add_to_collection
      @db_manga = DbManga.find(params[:id])
      @user_collection = current_user.user_collections.find(params[:user_collection_id])

      # Vérifier si ce manga n'est pas déjà dans la collection
      existing_manga = @user_collection.owned_mangas.find_by(db_manga: @db_manga)

      if existing_manga
        redirect_back(fallback_location: @db_manga,
                    alert: 'Ce manga est déjà dans cette collection.')
      else
        @owned_manga = @user_collection.owned_mangas.create!(
          db_manga: @db_manga,
          state: params[:state] || 'good',  # Utiliser 'state' au lieu de 'condition'
          available: true  # Par défaut disponible
        )

        redirect_back(fallback_location: @db_manga,
                    notice: "#{@db_manga.title} ajouté à #{@user_collection.name}.")
      end
  end
end
