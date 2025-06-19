class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @dbmangas = DbManga.all
  end

  def profile
    @user = current_user
    @page_title = "Mon Profil"
  end

  def notifications
    current_user.notifications.mark_as_read!
    @page_title = "Mes Notifs"
  end

  def calendar
    @exchanges = Exchange
      .where("initiator_id = ? OR recipient_id = ?", current_user.id, current_user.id)
      .includes(:wanted_manga, :offered_manga)

    start_date = params.fetch(:start_date, Date.today).to_date
    end_date = start_date.end_of_month

    @scheduled_exchanges = @exchanges.where(meeting_date: start_date..end_date)
    @page_title = "Mon Calendrier"
  end
end
