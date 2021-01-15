require 'solidus_core'
require 'solidus_support'

module Spree
  module EasyPost
    CONFIGS = { purchase_labels?: true }
  end
end

require 'easypost'
require 'spree_easypost/engine'
