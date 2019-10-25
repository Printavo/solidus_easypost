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
        @ep_shipment ||= ::EasyPost::Shipment.retrieve(selected_easy_post_shipment_id)
      else
        @ep_shipment = build_easypost_shipment
      end
    end

    private

    def selected_easy_post_rate_id
      selected_shipping_rate.easy_post_rate_id
    end

    def selected_easy_post_shipment_id
      selected_shipping_rate.easy_post_shipment_id
    end

    def build_easypost_shipment
      ::EasyPost::Shipment.create(
        to_address: order.ship_address.easypost_address,
        from_address: stock_location.easypost_address,
        parcel: to_package.easypost_parcel
      )
    end

    def rebuild_easypost_shipment
      new_ep_shipment = build_easypost_shipment
      new_ep_rates = new_ep_shipment.rates
      return if new_ep_rates.count < self.shipping_rates.count

      matches = {}

      new_ep_rates.each do |rate|
        old_rate = self.shipping_rates.find_by(name: "#{rate.carrier} #{rate.service}")
        for_selected_rate = "#{rate.carrier} #{rate.service}" == self.selected_shipping_rate.name

        if old_rate.blank?
          return if for_selected_rate
          next
        end

        difference_in_price = rate.rate.to_f - old_rate.cost.to_f
        return if difference_in_price != 0.0 && for_selected_rate

        matches[old_rate.easy_post_rate_id.to_s] = rate.id
      end

      return if matches.keys.count != self.shipping_rates.count

      matches.each do |old_rate_easypost_id, new_rate_easypost_id|
        old_rate = self.shipping_rates.find_by(easy_post_rate_id: old_rate_easypost_id)
        old_rate.update(easy_post_rate_id: new_rate_easypost_id, easy_post_shipment_id: new_ep_shipment.id)
      end

      new_ep_shipment
    end

    def buy_easypost_rate
      easypost_shipment = retrieve_or_build_easypost_shipment

      rate = easypost_shipment.rates.find do |rate|
        rate.id == selected_easy_post_rate_id
      end

      begin
        easypost_shipment.buy(rate) unless easypost_shipment.postage_label.present?
      rescue RuntimeError => exception
        new_easypost_shipment = rebuild_easypost_shipment
        raise exception if new_easypost_shipment.blank?

        new_rate = new_easypost_shipment.rates.find { |r| r.id == selected_shipping_rate.reload.easy_post_rate_id }
        new_easypost_shipment.buy(new_rate)
        easypost_shipment = new_easypost_shipment
      end

      self.tracking = easypost_shipment.tracking_code
      self.easy_post_public_tracking_url = easypost_shipment.tracker.public_url
      self.easy_post_postage_label_url = easypost_shipment.postage_label&.label_url
    end
  end
end

Spree::Shipment.prepend Spree::ShipmentDecorator
