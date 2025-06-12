class MessagebotsController < ApplicationController

  def create
    @chatbot = Chatbot.find(params[:chatbot_id])
    if @chatbot.ask(params[:messagebot][:content])
      redirect_to chat_path(@chatbot)
    else
      @messagebot = @chatbot.messagebots.last
      render "chats/show", status: :unprocessable_entity
    end
  end
end
