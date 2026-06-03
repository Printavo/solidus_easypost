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

  Spree::DummyGenerator.start ["--lib_name=#{ENV['LIB_NAME']}", "--quiet"]
  Solidus::InstallGenerator.start [
    "--lib_name=#{ENV['LIB_NAME']}", "--auto-accept",
    "--with-authentication=false", "--payment-method=none",
    "--migrate=false", "--seed=false", "--sample=false", "--quiet",
    "--user_class=Spree::LegacyUser"
  ]

  # Rails 8 / sprockets-rails 3.5 aborts boot with ManifestNeededError when the
  # generated dummy app has no app/assets/config/manifest.js, which happens
  # BEFORE db setup can run. Seed a minimal manifest so the app boots.
  # (mirrors solidusio/solidus#3379, solidusio/solidus#6327)
  manifest = File.join('spec', 'dummy', 'app', 'assets', 'config', 'manifest.js')
  unless File.exist?(manifest)
    require 'fileutils'
    FileUtils.mkdir_p(File.dirname(manifest))
    File.write(manifest, "//= link_tree ../images\n")
  end

  puts 'Setting up dummy database...'
  # rake test_app's chained db:create/db:migrate can leave the sqlite file empty;
  # run each step as a separate bin/rails invocation so a failure surfaces.
  Dir.chdir('spec/dummy') do
    sh 'bin/rails db:environment:set RAILS_ENV=test'
    sh 'bin/rails db:drop db:create RAILS_ENV=test'
    sh 'bin/rails db:migrate VERBOSE=false RAILS_ENV=test'
  end
end
