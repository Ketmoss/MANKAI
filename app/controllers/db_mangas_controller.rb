class DbMangasController < ApplicationController

  def index
    @dbmangas = DbManga.all
  end

  def show
    @dbmanga = DbManga.find(params[:id])
  end

end
