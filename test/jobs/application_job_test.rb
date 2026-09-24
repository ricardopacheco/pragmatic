# frozen_string_literal: true

require "test_helper"

class ApplicationJobTest < ActiveJob::TestCase
  Boom = Class.new(StandardError)

  class FailingJob < ApplicationJob
    def perform
      raise Boom
    end
  end

  test "a failure schedules the job again without reporting it" do
    TrackExceptionService.expects(:capture_exception).never

    assert_enqueued_with(job: FailingJob) { FailingJob.perform_now }
  end

  test "the last failure is reported and raised" do
    TrackExceptionService.expects(:capture_exception)
      .with(instance_of(Boom), has_entries(job: FailingJob.name, executions: ApplicationJob::MAX_RETRIES))

    error = assert_raises(Minitest::UnexpectedError) do
      perform_enqueued_jobs { FailingJob.perform_later }
    end

    assert_instance_of Boom, error.error
    assert_performed_jobs ApplicationJob::MAX_RETRIES
  end
end
