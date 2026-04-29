ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

if Rails.env.test?
  database_name = ActiveRecord::Base.connection.current_database

  unless database_name.start_with?("app_test")
    abort "Refusing to run tests against #{database_name.inspect}. Set DATABASE_URL to the test database, for example postgres://app:app@db:5432/app_test."
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
