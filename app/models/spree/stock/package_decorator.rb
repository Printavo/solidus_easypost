module Spree
  module Stock
    module PackageDecorator
      def easypost_parcel
        total_weight = contents.sum do |item|
          item.quantity * item.variant.weight
        end

        ::EasyPost::Parcel.create({ weight: total_weight }, easypost_api_key)
      end

      def easypost_shipment
        ::EasyPost::Shipment.create(
          {
            to_address: order.ship_address.easypost_address(easypost_api_key),
            from_address: stock_location.easypost_address(easypost_api_key),
            parcel: easypost_parcel
          },
          easypost_api_key
        )
      end

      private

      def easypost_api_key
        order&.account&.easypost_api_key
      end
    end
  end
end

Spree::Stock::Package.prepend Spree::Stock::PackageDecorator
