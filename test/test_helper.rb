ENV["RAILS_ENV"] ||= "test"

require "simplecov"

# Starts before the application is loaded: anything required during boot would
# otherwise be reported as never executed. Each run is named after its process so
# the two suites — `bin/rails test` and `bin/rails test:system` are separate
# processes — merge into a single report instead of overwriting each other.
SimpleCov.start "rails" do
  command_name "run-#{Process.pid}"
  merge_timeout 3600
end

require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    include FactoryBot::Syntax::Methods
    include ActionDispatch::TestProcess::FixtureFile
    include ActiveJob::TestHelper
    include ActionMailer::TestHelper

    # Add more helper methods to be used by all tests here...
  end
end
