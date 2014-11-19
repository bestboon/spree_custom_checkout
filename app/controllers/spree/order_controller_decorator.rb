module Spree
    OrdersController.class_eval do

      def edit
        @order = current_order || Order.incomplete.find_or_initialize_by(guest_token: cookies.signed[:guest_token])
        associate_user
        split_order
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

    end
end