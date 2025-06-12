class ChatbotsController < ApplicationController
before_action :authenticate_user!

def index
  @chatbots = current_user.chatbots # récupère les chatbots de l'utilisateur connecté
  @chatbot = Chatbot.new # pour le formulaire de création
end

def create
  @chatbot = current_user.chatbots.build(chatbot_params)
  if @chatbot.save
    redirect_to chatbot_path(@chatbot), notice: "Chat created successfully."
  else
    @chatbots = current_user.chatbots
    render :index
  end
end

def show
  @chatbot = current_user.chatbots.find(params[:id]) # s'assure que le chatbot appartient à l'utilisateur
  @messagebot = Messagebot.new
end

private

def chatbot_params
  params.require(:chatbot).permit(:name, :description) # ajustez selon vos attributs
end

end
