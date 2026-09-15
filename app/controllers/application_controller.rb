class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || dashboard_path_for(Current.user)
  end

  # Where each role lands: admins manage users, everyone else sees their own profile.
  def dashboard_path_for(user)
    user&.admin? ? admin_dashboard_path : profile_path
  end
end
