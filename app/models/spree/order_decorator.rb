module Spree
    Order.class_eval do
      checkout_flow do
        go_to_state :address
        go_to_state :delivery
        go_to_state :complete
      end

      # Finalizes an in progress order after checkout is complete.
      # Called after transition to complete state when payments will have been processed
      def finalize!
        # lock all adjustments (coupon promotions, etc.)
        all_adjustments.each{|a| a.close}

        # update payment and shipment(s) states, and save
        updater.update_payment_state
        shipments.each do |shipment|
          shipment.update!(self)
          shipment.finalize!
        end

        updater.update_shipment_state
        save!
        updater.run_hooks

        touch :completed_at

        # Deshabilitamos el envio de correos estandar de spree para gestionarlo de forma personalizada.
        # deliver_order_confirmation_email unless confirmation_delivered?

        consider_risk
      end
    end
end