module Spree
    Order.class_eval do
      checkout_flow do
        go_to_state :verification
        go_to_state :address
        go_to_state :complete
      end
    end
end