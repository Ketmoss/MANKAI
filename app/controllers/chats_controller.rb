class ChatsController < ApplicationController
  before_action :set_chat
  def index
    @exchange = Exchange.find(params[:exchange_id])
    @chats = current_user.chats.where(exchange: @exchange)
    @chat = Chat.new
  end

  def show
    unless @chat.exchange.initiator == current_user || @chat.exchange.recipient == current_user
      redirect_to root_path, alert: "Tu n'as pas accès à cette discussion."
    end
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

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end
end
