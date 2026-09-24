# frozen_string_literal: true

# Active sessions list, shown in the profile.
class SessionDecorator < Burgundy::Item
  BROWSERS = {
    "Edg" => "Edge", "OPR" => "Opera", "Chrome" => "Chrome", "Safari" => "Safari", "Firefox" => "Firefox"
  }.freeze

  PLATFORMS = {
    "Android" => "Android", "iPhone" => "iOS", "iPad" => "iPadOS", "Mac OS X" => "macOS",
    "Windows" => "Windows", "Linux" => "Linux"
  }.freeze

  attributes :id, :ip_address

  def initialize(session, current_session_id = nil)
    super(session)

    @current_session_id = current_session_id
  end

  def current?
    item.id == @current_session_id
  end

  # The raw user agent is unreadable in a list, so it is reduced to the browser and
  # the operating system when both can be recognized.
  def browser
    user_agent = item.user_agent
    return t("decorators.session.unknown_browser") if user_agent.blank?

    [browser_name, platform_name].compact.join(" · ").presence || user_agent.truncate(60)
  end

  def started_at
    l(item.created_at, format: :short)
  end

  def dom_id
    "session_#{item.id}"
  end

  private

  def browser_name
    BROWSERS.find { |token, _name| item.user_agent.include?(token) }&.last
  end

  def platform_name
    PLATFORMS.find { |token, _name| item.user_agent.include?(token) }&.last
  end
end
