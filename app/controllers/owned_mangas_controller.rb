class OwnedMangasController < ApplicationController
  def index
    @owned_mangas = OwnedManga.all
  end

  def show
    @user_collection = UserCollection.find(params[:user_collection_id])
    @owned_manga = OwnedManga.find(params[:id])
  end

  def new
    @owned_manga = OwnedManga.new
  end

  def create
    @user_collection = current_user.user_collections.find(params[:user_collection_id])
    @db_manga = DbManga.find(params[:dbmanga_id] || params[:db_manga_id])

    # Vérifier les doublons
    existing = @user_collection.owned_mangas.joins(:db_manga)
                              .where(db_manga: @db_manga).exists?

    if existing
      redirect_to @user_collection, alert: 'Ce manga est déjà dans votre collection'
      return
    end

    @owned_manga = @user_collection.owned_mangas.build(
      db_manga: @db_manga,
      state: params[:state] || 'good',
      available: true
    )

    if @owned_manga.save
      redirect_to user_collection_path(@user_collection),
                  notice: 'Manga ajouté à votre collection'
    else
      redirect_to db_mangas_path,
                  alert: 'Impossible d\'ajouter le manga'
    end
  end

  def edit;end

  def update;end

  def destroy
    @user_collection = current_user.user_collections.find(params[:user_collection_id])
    @owned_manga = @user_collection.owned_mangas.find(params[:id])
    @owned_manga.destroy

    redirect_to user_collection_path(@user_collection), notice: "Manga retiré de la collection."
  end


  private

  # def owned_manga_params
  #   # A determiner pour le permit, pour l'instant je l'ai parametré de maniere non definitive
  #   params.require(:owned_manga).permit()
  # end

  def set_owned_manga
      @owned_manga = OwnedManga.find(params[:db_manga_id])
  end
end
