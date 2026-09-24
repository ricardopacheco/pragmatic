# frozen_string_literal: true

require "test_helper"

class TrackExceptionServiceTest < ActiveSupport::TestCase
  test "reports the exception and its context to the Rails error reporter" do
    exception = StandardError.new("boom")

    report = assert_error_reported(StandardError) do
      TrackExceptionService.capture_exception(exception, import_id: 42)
    end

    assert_same exception, report.error
    assert_equal :error, report.severity
    assert_equal 42, report.context[:import_id]
  end
end
