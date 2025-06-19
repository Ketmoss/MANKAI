class DbMangasController < ApplicationController
  include Pagy::Backend

  def index
    @dbmangas = DbManga.all
    if params[:query].present?
      sql_subquery = "title ILIKE :query OR genre ILIKE :query OR author ILIKE :query"
      @dbmangas = @dbmangas.where(sql_subquery, query: "%#{params[:query]}%")
    end
      @pagy, @dbmangas = pagy(@dbmangas, items: 10)
    @page_title = "Chercher un manga"
  end

  def show
    @db_manga = DbManga.find(params[:id])
    @page_title = ""
  end

	def display_db_mangas_list
		@user_collection = UserCollection.find(params[:user_collection_id])
		@db_mangas = DbManga.all
    @page_title = "Mangas"
	end

  def add_to_collection
    @db_manga = DbManga.find(params[:id])
    @user_collection = current_user.user_collections.find(params[:user_collection_id])

    # Vérifier si ce manga n'est pas déjà dans la collection
    existing_manga = @user_collection.owned_mangas.find_by(db_manga: @db_manga)

    if existing_manga
      redirect_back(fallback_location: @db_manga,
                  alert: "Ce manga est déjà dans la collection #{@user_collection.name}.")
    else
      @owned_manga = @user_collection.owned_mangas.create!(
        db_manga: @db_manga,
        state: params[:state] || 'good',
        available_for_exchange: true
      )

      redirect_to user_collection_owned_manga_path(@user_collection, @owned_manga),
                notice: "#{@db_manga.title} ajouté à #{@user_collection.name}."
    end
  end

  def exchange_candidates
    @db_manga = DbManga.find(params[:id])

    available_mangas = OwnedManga
      .includes(user_collection: :user)
      .where(db_manga: @db_manga, available_for_exchange: true)
      .where.not(user_collections: { user_id: current_user.id })

    # Tri par distance géographique réelle
    if current_user&.latitude.present? && current_user&.longitude.present?
      @available_owned_mangas = available_mangas.sort_by do |owned|
        user = owned.user_collection.user
        if user.latitude.present? && user.longitude.present?
          FrenchGeocoderService.distance_between_coordinates(
            current_user.latitude, current_user.longitude,
            user.latitude, user.longitude
          )
        else
          Float::INFINITY
        end
      end
    else
      @available_owned_mangas = available_mangas
    end
  end

end
