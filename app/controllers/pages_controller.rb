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
    @page_title = "Mon Calendrier"
  end
end
