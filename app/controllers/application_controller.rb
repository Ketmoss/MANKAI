class ApplicationController < ActionController::Base
  include Pagy::Backend
  before_action :authenticate_user!
  before_action :set_notifications, if: :user_signed_in?
  before_action :configure_permitted_parameters, if: :devise_controller?

  def configure_permitted_parameters
    # # For additional fields in app/views/devise/registrations/new.html.erb
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :zip_code])

    # For additional in app/views/devise/registrations/edit.html.erb
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :avatar_url, :zip_code])
  end

  def default_url_options
    {host: ENV['www.mankai.me'] || 'localhost:3000' }
  end

  private

  def set_notifications
    @notifications = current_user.notifications.order(created_at: :desc)
  end
end
