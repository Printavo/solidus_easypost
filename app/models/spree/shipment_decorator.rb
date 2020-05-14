module Spree
  module ShipmentDecorator
    def self.prepended(mod)
      mod.state_machine.before_transition(
        from: :ready,
        to: :shipped,
        do: :buy_easypost_rate,
        if: -> { Spree::EasyPost::CONFIGS[:purchase_labels?] }
      )
    end

    def retrieve_or_build_easypost_shipment
      if selected_easy_post_shipment_id
        @ep_shipment ||= ::EasyPost::Shipment.retrieve(selected_easy_post_shipment_id, easypost_api_key)
      else
        @ep_shipment = build_easypost_shipment
      end
    end

    private

    def easypost_api_key
      order&.account&.easypost_api_key
    end

    def selected_easy_post_rate_id
      selected_shipping_rate.easy_post_rate_id
    end

    def selected_easy_post_shipment_id
      selected_shipping_rate.easy_post_shipment_id
    end

    def build_easypost_shipment
      ::EasyPost::Shipment.create(
        {
          to_address: order.ship_address.easypost_address(easypost_api_key),
          from_address: stock_location.easypost_address(easypost_api_key),
          parcel: to_package.easypost_parcel
        },
        easypost_api_key
      )
    end

    def rebuild_easypost_shipment
      new_ep_shipment = build_easypost_shipment
      new_ep_rates = new_ep_shipment.rates

      matching_rates = new_ep_rates.select do |ep_shipping_rate|
        next unless "#{ep_shipping_rate.carrier} #{ep_shipping_rate.service}" == selected_shipping_rate.name
        next unless selected_shipping_rate.shipping_method.code.match(/#{ep_shipping_rate.carrier_account_id}/)

        if selected_shipping_rate.flat_rate?
          ep_shipping_rate.rate.to_f <= selected_shipping_rate.actual_cost
        else
          ep_shipping_rate.rate.to_f <= selected_shipping_rate.cost
        end
      end

      if matching_rates.present?
        matching_rate = matching_rates.first
        previously_selected_shipping_rate = selected_shipping_rate

        shipping_method_to_update = selected_shipping_rate.shipping_method
        shipping_rates.where(shipping_method: shipping_method_to_update).each(&:destroy!)

        new_ep_rates.select { |epr| shipping_method_to_update.code.match(/#{epr.carrier_account_id}/) }.each do |ep_rate|
          shipping_rate_attrs = {
            name: "#{ep_rate.carrier} #{ep_rate.service}",
            cost: ep_rate.rate,
            easy_post_shipment_id: ep_rate.shipment_id,
            easy_post_rate_id: ep_rate.id,
            shipping_method: shipping_method_to_update
          }

          new_rate = Spree::ShippingRate.create!(shipping_rate_attrs)

          if ep_rate.id == matching_rate.id
            new_rate.selected = true

            if previously_selected_shipping_rate.flat_rate
              new_rate.flat_rate = true
              new_rate.actual_cost = new_rate.cost
              new_rate.cost = previously_selected_shipping_rate.cost
            end

            new_rate.save
          end

          self.shipping_rates << new_rate
        end

        new_ep_shipment
      else
        nil
      end
    end

    def buy_easypost_rate
      easypost_shipment = retrieve_or_build_easypost_shipment

      rate = easypost_shipment.rates.find do |rate|
        rate.id == selected_easy_post_rate_id
      end

      begin
        easypost_shipment.buy(rate) unless easypost_shipment.postage_label.present?
      rescue StandardError => exception
        new_easypost_shipment = rebuild_easypost_shipment
        raise exception if new_easypost_shipment.blank?

        new_rate = new_easypost_shipment.rates.find { |r| r.id == self.reload.selected_shipping_rate.easy_post_rate_id }
        new_easypost_shipment.buy(new_rate)
        easypost_shipment = new_easypost_shipment
      end

      self.tracking = easypost_shipment.tracking_code
      self.easy_post_public_tracking_url = easypost_shipment.tracker.public_url
      self.easy_post_postage_label_url = easypost_shipment&.postage_label&.label_url
    end

    Spree::Shipment.prepend(self) unless Spree::Shipment.ancestors.include?(self)
  end
end
