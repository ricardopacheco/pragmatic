# frozen_string_literal: true

# Decides which partial the view renders. Data comes from the controller, already
# decorated; the presenter never queries the database.
class ApplicationPresenter
  delegate :url_helpers, to: "Rails.application.routes"

  attr_reader :current_user

  def initialize(view_context, current_user, options = {})
    @view_context = view_context
    @current_user = current_user
    @options = options
  end

  def helpers
    @view_context
  end

  def render_partial_path(options = {})
    helpers.render(options)
  end

  private

  attr_reader :options
end
