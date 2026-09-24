# frozen_string_literal: true

# Single entry point to report exceptions. Hands them to the Rails error reporter, so
# whichever tool subscribes to it receives them without the callers knowing which one.
class TrackExceptionService
  def self.capture_exception(exception, context = {})
    Rails.error.report(exception, severity: :error, context:)
  end
end
