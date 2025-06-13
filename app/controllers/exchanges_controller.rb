class ExchangesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_exchange, only: [:show, :update, :destroy]

  # INDEX
  def index
    @exchanges = Exchange
      .where("initiator_id = ? OR recipient_id = ?", current_user.id, current_user.id)
      .includes(:wanted_manga, :offered_manga)
  end

  # NEW

  def new
    @wanted_manga = OwnedManga.find(params[:wanted_manga_id])
    @available_mangas = current_user.owned_mangas.where(available_for_exchange: true)
    @exchange = Exchange.new
  end


  # CREATE
  def create
      @wanted_manga = OwnedManga.find(params[:exchange][:wanted_manga_id])

      unless current_user.can_request_exchange_for?(@wanted_manga)
        flash[:alert] = "Un échange est déjà en cours pour ce manga. Merci d’attendre une réponse avant d’en proposer un autre."
        return redirect_to new_exchange_path(wanted_manga_id: @wanted_manga.id)
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
        flash.now[:alert] = "Erreur lors de la création de l’échange : #{@exchange.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
  end

  # SHOW
  def show
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
    end



  # UPDATE
  def update
      @exchange = Exchange.find(params[:id])

      unless @exchange.recipient == current_user
        redirect_to exchanges_path, alert: "Non autorisé."
        return
      end

      if @exchange.update(offered_manga_id: params[:exchange][:offered_manga_id])
        redirect_to exchange_path(@exchange), notice: "Vous avez proposé un manga en retour."
      else
        flash.now[:alert] = "Erreur : #{@exchange.errors.full_messages.join(', ')}"
        @available_mangas = @exchange.initiator.owned_mangas.where(available_for_exchange: true)
        render :edit, status: :unprocessable_entity
      end
  end

    #STATUS UPDATE
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

  # DELETE
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
