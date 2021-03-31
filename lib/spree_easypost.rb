require 'solidus_core'
require 'solidus_support'

module Spree
  module EasyPost
    CONFIGS = {
      purchase_labels?: true,
      excluded_shipping_rates: []
    }

    def self.allowed_rates(rates)
      rates.reject { |r| CONFIGS[:excluded_shipping_rates].include?(r["service"]) }
    end
  end
end

require 'easypost'
require 'spree_easypost/engine'
