module EasyPost
  module AddressDecorator
    def easypost_address(easypost_api_key)
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
      attributes[:residential] = residential if respond_to?(:residential)

      ::EasyPost::Address.create(attributes, easypost_api_key)
    end

    ::Spree::Address.prepend(self)
    ::Spree::StockLocation.prepend(self)
  end
end
