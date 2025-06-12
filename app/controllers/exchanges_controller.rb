class ExchangesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_exchange, only: [:show, :update, :destroy]

  # GET /exchanges
  def index
    @exchanges = Exchange
      .where("initiator_id = ? OR recipient_id = ?", current_user.id, current_user.id)
      .includes(:wanted_manga, :offered_manga)
  end

  # GET /exchanges/:id

  def new
    @wanted_manga = OwnedManga.find(params[:wanted_manga_id])
    @available_mangas = current_user.owned_mangas.where(available_for_exchange: true)
    @exchange = Exchange.new
  end


  # POST /exchanges
  def create
    @wanted_manga = OwnedManga.find(params[:wanted_manga_id])

    unless current_user.can_request_exchange_for?(@wanted_manga)
      return render json: { error: "Échange non autorisé" }, status: :forbidden
    end

    @exchange = Exchange.new(
      initiator: current_user,
      recipient: @wanted_manga.user_collection.user,
      wanted_manga: @wanted_manga,
      offered_manga_id: params[:offered_manga_id],
      initial_message: params[:initial_message]
    )

    if @exchange.save
      # Optionnel : création automatique du chat
      Chat.create(title: "Échange Manga", exchange: @exchange, user: current_user)
      render json: @exchange, status: :created
    else
      render json: @exchange.errors, status: :unprocessable_entity
    end
  end

  def show
  end

  # PATCH /exchanges/:id
  def update
    authorize_exchange!
    if @exchange.update(exchange_params)
      render json: @exchange
    else
      render json: @exchange.errors, status: :unprocessable_entity
    end
  end

  # DELETE /exchanges/:id
  def destroy
    authorize_exchange!
    @exchange.destroy
    head :no_content
  end

  private

  def set_exchange
    @exchange = Exchange.find(params[:id])
  end

  def exchange_params
    params.require(:exchange).permit(:status, :meeting_date, :meeting_location, :meeting_notes)
  end

  def authorize_exchange!
    unless @exchange.initiator == current_user || @exchange.recipient == current_user
      render json: { error: "Non autorisé" }, status: :forbidden
    end
  end
end
