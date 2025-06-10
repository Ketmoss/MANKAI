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
    @owned_manga = OwnedManga.new
    @user_collection = UserCollection.find(params[:user_collection_id])
    @db_manga = DbManga.find(params[:id])
    @owned_manga.user_collection = @user_collection
    @owned_manga.db_manga = @db_manga
    if @owned_manga.save!
      # user_collections/1/owned_mangas/1
      redirect_to user_collection_owned_manga_path(@user_collection, @owned_manga)
    else
      render "db_mangas/display_db_mangas_list", status: :unprocessable_entity
    end
  end

  def edit;end

  def update;end

  def destroy;end

  private

  # def owned_manga_params
  #   # A determiner pour le permit, pour l'instant je l'ai parametré de maniere non definitive
  #   params.require(:owned_manga).permit()
  # end

  def set_owned_manga
    # Provient de la db_mangas a tester lors du create
    @owned_manga = OwnedManga.find(params[:db_manga_id])
  end
end
