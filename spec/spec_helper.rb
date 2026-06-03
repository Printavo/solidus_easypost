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
# (chained db:create/db:migrate can leave the sqlite file empty). rspec runs
# from the gem root, so point the migration check at the dummy app's (absolute)
# db/migrate instead of the gem's own original migrations, which are unrecorded.
ActiveRecord::Migrator.migrations_paths =
  [File.expand_path('../dummy/db/migrate', __FILE__)]
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

# rspec runs from the gem root, where FactoryBot's default definition_file_paths
# (factories, spec/factories, ...) make factory_bot_rails auto-load our
# FactoryBot.modify overrides before Spree's core factories are registered. Load
# factory_bot first and blank the paths so the factory_bot_rails require pulled
# in by spree/testing_support/factory_bot doesn't auto-discover spec/factories.
require 'factory_bot'
FactoryBot.definition_file_paths = []
require 'spree/testing_support/factory_bot'

# Now pin Spree's core factory paths first, then this extension's factories
# (which use .modify and must resolve against the core definitions).
FactoryBot.definition_file_paths =
  Spree::TestingSupport::FactoryBot.definition_file_paths + [
    File.expand_path('../../lib/spree_easypost/factories', __FILE__),
    File.expand_path('factories/spree_modification', File.dirname(__FILE__))
  ]

# Load via the non-deprecated loader the in-tree deprecation points to
# (replaces require 'spree/testing_support/factories').
Spree::TestingSupport::FactoryBot.add_paths_and_load!

require 'spree/testing_support/controller_requests'
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/url_helpers'

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
