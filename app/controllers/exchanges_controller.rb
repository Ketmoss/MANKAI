class ExchangesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_exchange, only: [:show, :update, :destroy]

  # INDEX
  def index
    @exchanges = Exchange
      .where("initiator_id = ? OR recipient_id = ?", current_user.id, current_user.id)
      .includes(:wanted_manga, :offered_manga)

    # Compatible avec Simple Calendar - utilise meeting_date
    start_date = params.fetch(:start_date, Date.today).to_date
    end_date = start_date.end_of_month

    @scheduled_exchanges = @exchanges.where(meeting_date: start_date..end_date)
    @page_title = "Mes Échanges"
  end

  # NEW
  def new
    @wanted_manga = OwnedManga.find(params[:wanted_manga_id])
    @available_mangas = current_user.owned_mangas.where(available_for_exchange: true)
    @exchange = Exchange.new
    @page_title = "Envoie un message"
  end

  # CREATE
  def create
    @wanted_manga = OwnedManga.find(params[:exchange][:wanted_manga_id])

    unless current_user.can_request_exchange_for?(@wanted_manga)
      flash[:alert] = "Un échange est déjà en cours pour ce manga. Merci d'attendre une réponse avant d'en proposer un autre."
      return redirect_to new_exchange_path(wanted_manga_id: @wanted_manga.id)
    end

    existing_exchange = Exchange.find_by(
      initiator: current_user,
      recipient: @wanted_manga.user_collection.user,
      wanted_manga: @wanted_manga
    )

    if existing_exchange
      flash[:alert] = "Une demande d'échange identique existe déjà."
      return redirect_to exchanges_path
    end

    @exchange = Exchange.new(
      initiator: current_user,
      recipient: @wanted_manga.user_collection.user,
      wanted_manga: @wanted_manga,
      initial_message: params[:exchange][:initial_message]
    )

    if @exchange.save
      Chat.create(title: "Échange Manga", exchange: @exchange, user: current_user)
      redirect_to exchanges_path, notice: "Demande envoyée avec succès"
    else
      flash.now[:alert] = "Erreur lors de la création de l'échange : #{@exchange.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  # SHOW
  def show
    @chat = @exchange.chat
    @page_title = "Échange ##{@exchange.id}"
  end

  # EDIT
  def edit
    @exchange = Exchange.find(params[:id])

    unless @exchange.recipient == current_user
      redirect_to exchanges_path, alert: "Non autorisé."
      return
    end
    # On affiche la bibliothèque de l'initiateur
    @available_mangas = @exchange.initiator.owned_mangas.where(available_for_exchange: true)
    @page_title = "Choisis un Manga"
  end

  # UPDATE
  def update
    @exchange = Exchange.find(params[:id])

    unless @exchange.recipient == current_user
      redirect_to exchanges_path, alert: "Non autorisé."
      return
    end

    # Utilise meeting_date comme champ principal
    update_params = {
      offered_manga_id: params[:exchange][:offered_manga_id],
      status: params[:exchange][:status]
    }

    # Ajouter meeting_date si présent
    if params[:exchange][:meeting_date].present?
      update_params[:meeting_date] = params[:exchange][:meeting_date]
    end

    if @exchange.update(update_params)
      redirect_to exchange_path(@exchange), notice: "Vous avez proposé un manga en retour."
    else
      flash.now[:alert] = "Erreur : #{@exchange.errors.full_messages.join(', ')}"
      @available_mangas = @exchange.initiator.owned_mangas.where(available_for_exchange: true)
      render :edit, status: :unprocessable_entity
    end
  end

  # STATUS UPDATE
  def update_status
    @exchange = Exchange.find(params[:id])

    unless @exchange.initiator == current_user || @exchange.recipient == current_user
      redirect_to exchanges_path, alert: "Non autorisé." and return
    end

    if Exchange.statuses.keys.include?(params[:status])
      if @exchange.update(status: params[:status])
        redirect_to exchange_path(@exchange), notice: "Statut mis à jour avec succès."
      else
        redirect_to exchange_path(@exchange), alert: "Échec de la mise à jour du statut."
      end
    else
      redirect_to exchange_path(@exchange), alert: "Statut invalide."
    end
  end

  # SET DATE - Compatible Simple Calendar
  def set_date
    @exchange = Exchange.find(params[:id])

    unless @exchange.initiator == current_user || @exchange.recipient == current_user
      redirect_to exchange_path(@exchange), alert: "Non autorisé." and return
    end

    # Utilise meeting_date
    meeting_time = params[:exchange][:meeting_date]

    if @exchange.update(meeting_date: meeting_time)
      redirect_to exchange_path(@exchange), notice: "Date enregistrée avec succès."
    else
      redirect_to exchange_path(@exchange), alert: "Erreur lors de l'enregistrement de la date."
    end
  end

  # DELETE
  def destroy
    authorize_exchange!
    @exchange.destroy
    redirect_to exchanges_path, notice: "Échange supprimé avec succès."
  end

  # START CHAT
  def start_chat
    @exchange = Exchange.find(params[:id])

    if @exchange.chat.present?
      redirect_to chat_path(@exchange.chat)
    else
      @chat = Chat.create!(exchange: @exchange, user: current_user, title: "Échange Manga")
      redirect_to chat_path(@chat)
    end
  end

  private

  def set_exchange
    @exchange = Exchange.find(params[:id])
  end

  def exchange_params
    # Utilise meeting_date comme champ principal
    params.require(:exchange).permit(:status, :meeting_date, :meeting_location, :meeting_notes)
  end

  def authorize_exchange!
    unless @exchange.initiator == current_user || @exchange.recipient == current_user
      render json: { error: "Non autorisé" }, status: :forbidden
    end
  end
end
