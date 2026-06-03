# FactoryGirl was renamed to FactoryBot; static attributes must use block syntax
# on factory_bot 4.x to avoid the class-level Deprecation.warn that crashes on
# Rails 7.1+ (mirrors solidusio-contrib/solidus_easypost#29, 28829cd / 6eb1a25).
FactoryBot.define do
  # Define your Spree extensions Factories within this file to enable applications, and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'spree_easypost/factories'
end

FactoryBot.modify do
  factory :address do
    lastname { "Doe" }
  end

  factory :variant do
    weight { 10.0 }
  end

  factory :shipment do
    transient do
      inventory_units { 1 }
    end

    after(:create) do |shipment, e|
      create_list(:inventory_unit, e.inventory_units, shipment: shipment)
    end
  end
end
