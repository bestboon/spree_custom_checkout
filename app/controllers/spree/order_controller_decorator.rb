module Spree
    OrdersController.class_eval do

      def edit
        @order = current_order || Order.incomplete.find_or_initialize_by(guest_token: cookies.signed[:guest_token])
        associate_user
        split_order
      end

      # Funcion que se encarga de dividir las ordenes para ser mostradas por taxonomias en la pantalla del
      # carrito de compra.
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
    end
end