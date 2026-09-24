class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def presenter_class
    "#{controller_path.camelize}Presenter".constantize
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || current_user_dashboard_path
  end

  # Where each role lands: admins manage users, everyone else sees their own profile.
  def current_user_dashboard_path
    Current.user&.admin? ? admin_dashboard_path : profile_path
  end
end
