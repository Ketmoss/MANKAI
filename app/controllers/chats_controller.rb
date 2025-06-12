class ChatsController < ApplicationController
  def index
    @exchange = Exchange.find(params[:exchange_id])
    @chats = current_user.chats.where(exchange: @exchange)
    @chat = Chat.new
  end

  def show
    @chat = Chat.find(params[:id])
    @message = Message.new
  end

  def create
    @exchange = Exchange.find(params[:exchange_id])
    @chat = Chat.new(title: "Organise ton échange")
    @chat.exchange = @exchange
    @chat.user = current_user
    if @chat.save
      redirect_to chat_path(@chat)
    else
      render :index
    end
  end
end
