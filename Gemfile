source 'https://rubygems.org'

# Consume the Printavo Solidus fork (Solidus 2.11.16 + Rails 8 compat +
# state_machines <0.10 pin); the branch boots on both Rails 7.2 and 8.0.
gem 'solidus', git: 'https://github.com/Printavo/solidus.git', branch: 'rails-8.0-support'
gem 'solidus_auth_devise', '~> 2.5'

# Rails version is driven by the harness so both axes can be exercised from the
# same checkout: RAILS_VERSION='~> 7.2.0' / '~> 8.0'.
gem 'rails', ENV['RAILS_VERSION'], require: false

# The dummy app runs on sqlite (DB=sqlite); pg/mysql2 were CI-only adapters and
# their native builds need client libs absent from the dev/test sandbox.

gemspec
