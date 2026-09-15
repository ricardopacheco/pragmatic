ENV["RAILS_ENV"] ||= "test"

require "simplecov"

# Starts before the application is loaded: anything required during boot would
# otherwise be reported as never executed. Each run is named after its process so
# the two suites — `bin/rails test` and `bin/rails test:system` are separate
# processes — merge into a single report instead of overwriting each other.
SimpleCov.start "rails" do
  command_name "run-#{Process.pid}"
  merge_timeout 3600

  minimum_coverage line: 60
end

require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Every worker is a separate process, so each one needs its own name and has to
    # write its result before exiting, or only one worker's coverage would count.
    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
    end

    parallelize_teardown do |_worker|
      SimpleCov.result
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
