module Integrations
  class ImageSyncer
    attr_reader :firestore_catalog, :asset_service, :main_upload_path, :threads

    def initialize(firestore_catalog:)
      @firestore_catalog = firestore_catalog
      @asset_service = Assets::Client.new
      @main_upload_path = "integration_catalogs/#{firestore_catalog[:name]}/images"
      @threads = Rails.application.secrets.integrations[:number_of_threads_for_syncing]
    end

    def sync
      sync_items
      sync_bundles
      sync_products
      sync_customization_options
      firestore_catalog
    end

    private

    def sync_items
      size = firestore_catalog[:items].keys.length - 1
      Parallel.each(0..size, in_threads: threads) do |i|
        key = firestore_catalog[:items].keys[i]
        item = firestore_catalog[:items][key]
        puts "#ImageSyncer: Syncing Item: #{key}"
        sync_images(item, "items")
      end
    end

    def sync_bundles
      size = firestore_catalog[:bundles].keys.length - 1
      Parallel.each(0..size, in_threads: threads) do |i|
        key = firestore_catalog[:bundles].keys[i]
        bundle = firestore_catalog[:bundles][key]
        puts "#ImageSyncer: Syncing Bundle: #{key}"
        sync_images(bundle, "bundles")
      end
    end

    def sync_products
      size = firestore_catalog[:products].keys.length - 1
      Parallel.each(0..size, in_threads: threads) do |i|
        key = firestore_catalog[:products].keys[i]
        product = firestore_catalog[:products][key]
        puts "#ImageSyncer: Syncing Product: #{key}"
        sync_images(product, "products")
      end
    end

    def sync_customization_options
      size = firestore_catalog[:customization_options].keys.length - 1
      Parallel.each(0..size, in_threads: threads) do |i|
        key = firestore_catalog[:customization_options].keys[i]
        customization_option = firestore_catalog[:customization_options][key]
        puts "#ImageSyncer: Syncing Customization Option: #{key}"
        sync_images(customization_option, "customization_options")
      end
    end

    def sync_images(object, bucket_name)
      object[:images].each do |image_key, image|
        url = asset_service.request_image_upload(
          image_url: image,
          upload_path: "#{main_upload_path}/#{bucket_name}/#{object[:id]}/#{image_key}.jpg"
        )

        if url
          object[:images][image_key] = url
        else
          object[:images].delete(image_key)
        end
      end
    end
  end
end
