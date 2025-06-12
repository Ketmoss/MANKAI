class ExchangesController < ApplicationController
before_action :set_manga,  only: %i[new create]

  def index
    @exchanges = Exchange.all
  end

  def new
    @exchange = Exchange.new
  end

  def create
    @exchange = Exchange.new(exchange_params)
    @exchange.owned_manga = @owned_manga
    @exchange.user = current_user #à checker

    if @exchange.save
      redirect_to exchanges_path, notice: "Demande envoyée !"
    else
      render :new
    end
  end

  def edit
    @exchange = Exchange.find(params[:id])
  end

  def update
    @exchange = Exchange.find(params[:id])
    if @exchange.upate(exchange_params)
      redirect_to exchange_path(@exchange), notice: " Echange mis à jour !"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @exchange = Exchange.find(params[:id])
  end

  private

  def set_manga
    @manga = OwnedManga.find(params[:owned_manga_id]) # à checker !
  end

  def exchange_params
    params.require(:exchange).permit(:status)
  end
end
