class ChatbotsController < ApplicationController
  before_action :authenticate_user!
  # Sert trouver le chatbot correspondant à l’ID passé dans l’URL
  # et à vérifier qu’il appartient bien à l’utilisateur connecté.
  before_action :set_chatbot, only: [:show]
  def index
    # ici, le dernier chatbot est affiché en haut avec created_at: :desc
    @chatbots = current_user.chatbots.order(created_at: :desc)
    @chatbot = Chatbot.new # pour le formulaire de création
  end

  def create
    # Si aucun paramètre fourni (ex: bouton "Nouveau chat" sans form), on build un chat vide
  if params[:chatbot].blank?
    @chatbot = current_user.chatbots.build(model_id: "gpt-4o")
  else
    @chatbot = current_user.chatbots.build(chatbot_params)
    @chatbot.model_id ||= "gpt-4o"
  end

  if @chatbot.save
    redirect_to chatbot_path(@chatbot), notice: "Chat créé avec succès."
  else
    @chatbots = current_user.chatbots.order(created_at: :desc)
    flash.now[:alert] = "Erreur à la création du chat."
    render :index, status: :unprocessable_entity
  end
end

  def show
    @messagebot = Messagebot.new
    @messages = @chatbot.messagebots.order(:created_at)
  end

  def destroy
    @chatbot = current_user.chatbots.find(params[:id])
    @chatbot.destroy
    redirect_to chatbots_path, notice: "Discussion supprimée avec succès."
  end

  private

  def set_chatbot
    @chatbot = current_user.chatbots.find(params[:id])
  end

  def chatbot_params
    params.require(:chatbot).permit(:title, :model_id, :db_manga_id)
  end
end
