brands = JSON.parse(File.read("brands.json"))
stores = JSON.parse(File.read("stores.json"))

bs = Stores::BrandService.new

brands.each do |brand|
  bs.upsert(attributes: brand)
end

ss = Stores::StoreService.new

stores.each do |store|
  ss.upsert(attributes: store)
end
