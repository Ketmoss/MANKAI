class UserCollectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_collection, only: [:show, :edit, :update, :destroy]

  def index
    @usercollections = current_user.user_collections
    @owned_mangas = current_user.owned_mangas
    @db_mangas = DbManga.all
  end

  def show
    @owned_mangas = @user_collection.owned_mangas
    @db_mangas = DbManga.all

    respond_to do |format|
      format.html
      format.json { render json: @user_collection }
    end
  end

  def new
    @user_collection = current_user.user_collections.build
    @owned_mangas = current_user.owned_mangas # Seulement les mangas de l'user
    @db_mangas = DbManga.all

    respond_to do |format|
      format.html
      format.json { render json: @user_collection }
    end
  end

  def create
    @user_collection = current_user.user_collections.build(user_collection_params)

    if @user_collection.save
      redirect_to @user_collection, notice: 'Collection créée avec succès.'
    else
      @owned_mangas = current_user.owned_mangas
      @db_mangas = DbManga.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @owned_mangas = @user_collection.owned_mangas
    @db_mangas = DbManga.all

    respond_to do |format|
      format.html
      format.json { render json: @user_collection }
    end
  end

  def update
    if @user_collection.update(user_collection_params)
      redirect_to @user_collection, notice: 'Collection mise à jour avec succès.'
    else
      @owned_mangas = @user_collection.owned_mangas
      @db_mangas = DbManga.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user_collection.destroy
    redirect_to user_collections_path, notice: 'Collection supprimée avec succès.'
  end

  private

  def set_user_collection
    @user_collection = current_user.user_collections.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to user_collections_path, alert: 'Collection introuvable.'
  end

  def user_collection_params
    params.require(:user_collection).permit(:name)
  end
end
