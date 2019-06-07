module Spree
  module EasyPost
    module AddressDecorator
      def easypost_address
        attributes = {
          street1: address1,
          street2: address2,
          city: city,
          zip: zipcode,
          phone: phone
        }

        attributes[:company] = company if respond_to?(:company)
        attributes[:company] ||= company_name if respond_to?(:company_name)

        attributes[:name] = full_name if respond_to?(:full_name)
        attributes[:state] = state ? state.abbr : state_name
        attributes[:country] = country.try(:iso)

        ::EasyPost::Address.create attributes
      end
    end
  end
end

Spree::Address.prepend Spree::EasyPost::AddressDecorator
Spree::StockLocation.prepend Spree::EasyPost::AddressDecorator
