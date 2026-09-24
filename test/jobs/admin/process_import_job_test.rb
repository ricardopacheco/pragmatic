# frozen_string_literal: true

require "test_helper"

module Admin
  class ProcessImportJobTest < ActiveJob::TestCase
    test "processes the import" do
      import = create(:import)

      assert_difference -> { User.count }, 2 do
        ProcessImportJob.perform_now(import.id)
      end

      assert_predicate import.reload, :completed_with_errors?
    end

    test "a missing import is a failure of the operation, not an error to report" do
      TrackExceptionService.expects(:capture_exception).never

      assert_nothing_raised { ProcessImportJob.perform_now(0) }
    end

    test "an unexpected error is reported and raised, with no retry" do
      import = create(:import)
      ProcessImportOperation.stubs(:call).raises(ActiveRecord::ConnectionNotEstablished)
      TrackExceptionService.expects(:capture_exception)
        .with(instance_of(ActiveRecord::ConnectionNotEstablished), has_entries(job: ProcessImportJob.name))

      assert_no_enqueued_jobs(only: ProcessImportJob) do
        assert_raises(ActiveRecord::ConnectionNotEstablished) { ProcessImportJob.perform_now(import.id) }
      end
    end
  end
end
