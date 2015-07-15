module Spree
    CheckoutController.class_eval do

      def before_address
        # if the user has a default address, a callback takes care of setting
        # that; but if he doesn't, we need to build an empty one here
        @order.bill_address ||= Address.build_default
        @order.ship_address ||= Address.build_default if @order.checkout_steps.include?('delivery')      
      end

      def update
        if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
          @order.temporary_address = !params[:save_user_address]
          unless @order.next
            flash[:error] = @order.errors.full_messages.join("\n")
            redirect_to checkout_state_path(@order.state) and return
          end

          if @order.completed?
            # Almacenamos la orden actual como la principal
            @main_order = @current_order
            # Hacemos nula la orden actual
            @current_order = nil
            # Dividimos la orden por taxonomis y numero de lineas.
            split_order
            # Generamos las ordenes nuevas por taxonomias y limite de lineas
            generate_orders
            # Eliminamos la orden principal.
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

      # Metodo que se encarga de eliminar la orden principal y sus lineas
      def delete_lines_main_order
        # Eliminamos las lineas de la orden principal
        @main_order.line_items.each do |line_item|
          line_item.delete
        end
        # Eliminamos la orden principal
        @main_order.delete
      end

      # Metodo que se encarga de dividir las ordenes por taxonomias.
      def split_order
        # Lineas de productos identificadas por taxonomias
        @taxonomias = Spree::Taxon.where(parent_id: [1])
        # Creamos el hash de array donde almacenaremos las lineas de productos por taxonomias.
        @productos_por_taxonomias =  Hash.new
        # LLenamos el hash
        @taxonomias.each do |taxonomia|
          @productos_por_taxonomias[taxonomia.name] = []
        end
        @order.line_items.each do |item|
          item.variant.product.taxons.each do |taxon|
            if @productos_por_taxonomias[taxon.parent.name]
              @productos_por_taxonomias[taxon.parent.name].append(item)
            end
          end
        end
      end

      # Metodo que se encarga de generar las nuevas ordenes partiendo de la principal
      # tomando encuenta las taxonomias y el limite de lineas por factura configurado.
      def generate_orders
        @productos_por_taxonomias.each do |taxonomia, line_items|
          # Picamos la orden actual en sub-ordenes si la orden excede la cantidad de lineas configuradas en el backend par auna orden.
          line_items.each_slice(Spree::Config[:max_order_lines]) do |line_items_slice|
            line_items_slice.each do |line_item|
              @current_order = nil
              populator = Spree::OrderPopulator.new(current_order(create_order_if_necessary: true), current_currency)
              populator.populate(line_item.variant_id, line_item.quantity)
            end
          @current_order.next
          @current_order.next
          @current_order.next
          # Envio de correo si esta habilitada la opcion 'enable_mail_delivery'
          # en las configuraciones de envio de correo en backend.
          OrderMailer.confirm_email(@current_order).deliver if Spree::Config[:enable_mail_delivery]
          end
        end
      end
    #fin controlador
    end
# fin modulo
end