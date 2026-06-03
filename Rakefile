require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

task :default do
  if Dir["spec/dummy"].empty?
    Rake::Task[:test_app].invoke
    Dir.chdir("../../")
  end
  Rake::Task[:spec].invoke
end

desc 'Generates a dummy app for testing'
task :test_app do
  ENV['LIB_NAME'] = 'spree_easypost'
  ENV['RAILS_ENV'] = 'test'

  require 'spree/testing_support/common_rake'
  require ENV['LIB_NAME']

  dummy_root = File.expand_path('spec/dummy', __dir__)

  Spree::DummyGenerator.start ["--lib_name=#{ENV['LIB_NAME']}", "--quiet"]

  # Rails 8 / sprockets-rails 3.5 aborts boot with ManifestNeededError when the
  # generated dummy app has no app/assets/config/manifest.js. The Solidus
  # install generator below boots the app, so seed the manifest first.
  # (mirrors solidusio/solidus#3379, solidusio/solidus#6327)
  require 'fileutils'
  manifest = File.join(dummy_root, 'app', 'assets', 'config', 'manifest.js')
  unless File.exist?(manifest)
    FileUtils.mkdir_p(File.dirname(manifest))
    File.write(manifest, "//= link_tree ../images\n")
  end

  Solidus::InstallGenerator.start [
    "--lib_name=#{ENV['LIB_NAME']}", "--auto-accept",
    "--with-authentication=false", "--payment-method=none",
    "--migrate=false", "--seed=false", "--sample=false", "--quiet",
    "--user_class=Spree::LegacyUser"
  ]

  puts 'Setting up dummy database...'
  # rake test_app's chained db:create/db:migrate can leave the sqlite file empty;
  # run each step as a separate bin/rails invocation so a failure surfaces. The
  # in-process generators leave the process inside spec/dummy and mangle
  # bundler's env, so resolve the dummy app by absolute path and shell out with
  # the original env and an explicit ruby interpreter for each db step.
  Bundler.with_original_env do
    Dir.chdir(dummy_root) do
      sh "#{RbConfig.ruby} ./bin/rails db:environment:set RAILS_ENV=test"
      sh "#{RbConfig.ruby} ./bin/rails db:drop db:create RAILS_ENV=test"
      sh "#{RbConfig.ruby} ./bin/rails db:migrate VERBOSE=false RAILS_ENV=test"
    end
  end
end
