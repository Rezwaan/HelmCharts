module Rush
  module Workers
    class KuduOrderSyncer
      include Sidekiq::Worker

      def perform
        sdm_order_ids_range.each_with_index do |sdm_order_id, i|
          throughput_per_second = (max_bound / 60).to_i

          Rush::Workers::KuduOrderPersister.perform_in(
            throughput_per_second * i,
            sdm_order_id,
          )
        end
      end

      private

      def kudu_platform
        Platforms::Platform.find_or_create_by(backend_id: "kudu_sdm")
      end

      def sdm_order_ids_range
        starting_id = starting_sdm_order_id
        starting_id..(starting_id + max_bound)
      end

      def starting_sdm_order_id
        # rubocop:disable Style/GlobalVars
        last_checked_order_id = 0
        $redis.with do |redis|
          last_checked_order_id = redis.get("rush:kudu:last_checked_id").to_i
        end
        # rubocop:enable Style/GlobalVars

        last_saved_order_id = Orders::Order.where(platform_id: kudu_platform.id)
          .maximum(:backend_id).to_i

        # Use this if nothing is in the database yet
        default_starting_order_id = 16_056_500

        [last_checked_order_id, last_saved_order_id, default_starting_order_id].max
      end

      def max_bound
        60
      end
    end
  end
end
