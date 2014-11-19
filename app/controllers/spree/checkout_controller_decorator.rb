module Spree
    CheckoutController.class_eval do

      def before_address
        # if the user has a default address, a callback takes care of setting
        # that; but if he doesn't, we need to build an empty one here
        @order.bill_address ||= Address.build_default
        @order.ship_address ||= Address.build_default if @order.checkout_steps.include?('delivery')
        split_order
      end

      def update
        if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
          @order.temporary_address = !params[:save_user_address]
          unless @order.next
            flash[:error] = @order.errors.full_messages.join("\n")
            redirect_to checkout_state_path(@order.state) and return
          end

          if @order.completed?
            @main_order = @current_order
            @current_order = nil
            generate_orders
            delete_lines_main_order
            flash.notice = Spree.t(:order_processed_successfully)
            flash['order_completed'] = true
            redirect_to account_path
          else
            redirect_to checkout_state_path(@order.state)
          end
        else
          render :edit
        end
      end

      def delete_lines_main_order
        @main_order.line_items.each do |line_item|
          line_item.delete
        end
        @main_order.delete
      end

      def split_order
        # Lineas de productos identificadas por taxonomias
        @taxonomias = Spree::Taxonomy.all
        @productos_por_taxonomias =  Hash.new
        @taxonomias.each do |taxonomia|
          @productos_por_taxonomias[taxonomia.name] = []
        end
        @order.line_items.each do |item|
          item.variant.product.taxons.each do |taxon|
            if @productos_por_taxonomias[taxon.name]
              @productos_por_taxonomias[taxon.name].append(item)
            end
          end
        end
      end

      def generate_orders
        @productos_por_taxonomias.each do |clave, valor|
          @current_order = nil
          populator = Spree::OrderPopulator.new(current_order(create_order_if_necessary: true), current_currency)
          valor.each do |item|
            populator.populate(item.variant_id, item.quantity)
          end
          @current_order.next
          @current_order.next
        end
      end
    #fin controlador
    end
# fin modulo
end