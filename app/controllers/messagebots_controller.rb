class MessagebotsController < ApplicationController
  def index
    @messages = Messagebot.joins(:chatbot).where(chatbots: { user: current_user }).order(:created_at)
  end

  def new
    @message = Messagebot.new
  end
  def create
    @chatbot = Chatbot.find(params[:chatbot_id])
    if @chatbot.ask(params[:messagebot][:content])
      redirect_to chat_path(@chatbot)
    else
      @messagebot = Messagebot.new
      @messages = @chatbot.messagebots.order(:created_at)
      render "chatbots/show", status: :unprocessable_entity
    end
  end

  def show
    @message = Messagebot.find(params[:id])
  end
end
