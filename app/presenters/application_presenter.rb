# frozen_string_literal: true

# Decides which partial the view renders. Data comes from the controller, already
# decorated; the presenter never queries the database.
class ApplicationPresenter
  def initialize(view_context, options = {})
    @view_context = view_context
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
