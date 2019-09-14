s = Brands::Brand.all.map { |brand|
  {
    backend_id: brand.id,
    logo: brand.logo.url,
    name: brand.name,
    platform_id: 3,
  }
}.to_json
File.write("brands.json", s)

s = PickupLocations::PickupLocation.where.not(brand_id: nil).map { |store|
  {
    backend_id: store.id,
    brand_id: store.brand_id,
    latitude: store.lonlat.latitude,
    longitude: store.lonlat.longitude,
    name: store.description,
    platform_id: 3,
  }
}.to_json
File.write("stores.json", s)

# curl --upload-file ./brands.json http://w.hbu50.com:8080/brands.json
# curl --upload-file ./stores.json http://w.hbu50.com:8080/stores.json
# http://w.hbu50.com:8080/xD90p/stores.json
# http://w.hbu50.com:8080/7kgDs/brands.json
