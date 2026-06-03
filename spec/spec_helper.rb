# Run Coverage report
require 'pry'
require 'simplecov'
SimpleCov.start do
  add_filter 'spec/dummy'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Models', 'app/models'
  add_group 'Views', 'app/views'
  add_group 'Libraries', 'lib'
end

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)

# Recover from a dummy app whose schema wasn't fully loaded by rake test_app
# (chained db:create/db:migrate can leave the sqlite file empty).
ActiveRecord::Migration.maintain_test_schema!

require 'rspec/rails'
require 'database_cleaner'
require 'ffaker'
require 'vcr'
require 'webmock/rspec'

# Rails 8 / Psych 4 reject arbitrary YAML classes; permit the column types Spree
# serializes (mirrors solidusio/solidus#4451).
ActiveRecord.yaml_column_permitted_classes |= [BigDecimal, Date, Symbol, Time]

EasyPost.api_key = 'CvzYtuda6KRI9JjG7SAHbA'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

require 'spree/testing_support/factory_bot'

# When the dummy app is pre-booted via require 'environment', factory_bot_rails'
# path-setup initializer has already run, so pin the dummy app's factory path
# before loading so our spec_modification overrides resolve against Spree's
# core factories.
FactoryBot.definition_file_paths << File.expand_path('../dummy/spec/factories', __FILE__)

# Load Spree core factories via the non-deprecated loader the in-tree
# deprecation points to (replaces require 'spree/testing_support/factories').
Spree::TestingSupport::FactoryBot.add_paths_and_load!

require 'spree/testing_support/controller_requests'
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/url_helpers'

# Requires factories defined in lib/spree_easypost/factories.rb
require 'spree_easypost/factories'
require 'factories/spree_modification'

require 'helpers/shipping_method_helpers'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # == URL Helpers
  #
  # Allows access to Spree's routes in specs:
  #
  # visit spree.admin_path
  # current_path.should eql(spree.products_path)
  config.include Spree::TestingSupport::UrlHelpers
  config.include ShippingMethodHelpers

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec
  config.color = true

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]

  # Capybara javascript drivers require transactional fixtures set to false, and we use DatabaseCleaner
  # to cleanup after each test instead.  Without transactional fixtures set to false the records created
  # to setup a test will be unavailable to the browser, which runs under a separate server instance.
  config.use_transactional_fixtures = false

  # Ensure Suite is set to use transactions for speed.
  config.before :suite do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
  end

  # Before each spec check if it is a Javascript test and switch between using database transactions or not where necessary.
  config.before :each do |example|
    DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.start
  end

  # After each spec clean the database.
  config.after :each do
    DatabaseCleaner.clean
  end

  config.fail_fast = ENV['FAIL_FAST'] || false
end
