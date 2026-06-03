# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'solidus_easypost'
  s.version     = '1.0.5'
  s.summary     = 'Easy post integration for Solidus'
  s.description = 'Easy post integration for Solidus'
  s.required_ruby_version = '>= 2.1.0'

  s.author    = 'Brendan Deere'
  s.email     = 'brendan@stembolt.com'
  s.homepage  = 'https://github.com/solidusio-contrib/solidus_easypost'

  #s.files       = `git ls-files`.split("\n")
  #s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'solidus', ['>= 1.1', '< 3.x']
  s.add_dependency 'solidus_support', '>= 0.1.1'
  # easypost 2.x calls URI.escape (removed in Ruby 3.0); the Net::HTTP rewrite
  # in 3.1.0 switched the request path to CGI.escape, keeping the same positional
  # create(attrs, api_key) API (mirrors EasyPost/easypost-ruby#89). Aligns with
  # the Printavo app, which already locks easypost 3.4.0.
  s.add_dependency 'easypost', '~> 3.4'

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner', '~> 2.0'
  # factory_girl renamed to factory_bot; 4.x is the last line compatible with the
  # static deprecation path Solidus 2.11 testing-support relies on (resolves 4.11.1).
  s.add_development_dependency 'factory_bot_rails', '~> 4.8'
  s.add_development_dependency 'ffaker'
  # rspec-rails 8 dropped fixture_path=; 7.1 keeps it for the spec_helper idiom.
  s.add_development_dependency 'rspec-rails', '~> 7.1'
  s.add_development_dependency 'rails-controller-testing' # restores assigns/assert_template
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sprockets', '~> 4'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'vcr'
  s.add_development_dependency 'webmock'
end
