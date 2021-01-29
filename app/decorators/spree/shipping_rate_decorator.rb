module ShippingRateDecorator
  def name
    read_attribute(:name) || super
  end

  ::Spree::ShippingRate.prepend(self)
end
