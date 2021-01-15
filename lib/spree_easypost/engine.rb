require 'solidus_support'

module Spree
  module EasyPost
    class Engine < Rails::Engine
      include SolidusSupport::EngineExtensions

      require 'spree/core'
      isolate_namespace Spree
      engine_name 'spree_easypost'

      # use rspec for tests
      config.generators do |g|
        g.test_framework :rspec
      end
    end
  end
end
