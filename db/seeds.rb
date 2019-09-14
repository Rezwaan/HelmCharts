return unless Rails.env == "development"

admin = Accounts::Account.create(name: "Admin", username: "admin", password: "12345678")
admin.roles.create(role: "admin")

platform_attributes = {
  "id": 1,
  "backend_id": 1,
  "name_en": "Swyft",
  "name_ar": "سويفت",
  "logo_url": "https://storage.googleapis.com/swyft-production/logos/swyft-logo.jpg",
}

Platforms::Platform.create(platform_attributes)

brand_categories_attributes = [
  {
    id: 2,
    key: "restaurant",
  },
]

brand_categories_attributes.each do |a|
  Brands::Categories::BrandCategory.create(a)
end

brands_attributes = [
  {
    "id": 1,
    "platform_id": 1,
    "brand_category_id": 2,
    "backend_id": 416,
    "name_en": "Bash Manoush",
    "logo_url": "https://swyft-staging.storage.googleapis.com/brands/brands/logos/000/000/416/main/8df89702ab9c89069113ac7e353695a8-thumb.jpg?1556119495",
    "cover_photo_url": "https://swyft-staging.storage.googleapis.com/brands/brands/logos/000/000/416/main/8df89702ab9c89069113ac7e353695a8-thumb.jpg?1556119495",
  },
  {
    "id": 2,
    "backend_id": 30,
    "brand_category_id": 2,
    "logo_url": "https://swyft-production.storage.googleapis.com/brands/brands/logos/000/000/030/original/c59ffce2e9a102d7ba32a1850c325feb-original.png?1549904208",
    "cover_photo_url": "https://swyft-production.storage.googleapis.com/brands/brands/logos/000/000/030/original/c59ffce2e9a102d7ba32a1850c325feb-original.png?1549904208",
    "name": "Herfy",
    "platform_id": 1,
  },
  {
    "id": 3,
    "backend_id": 45,
    "brand_category_id": 2,
    "logo_url": "https://swyft-production.storage.googleapis.com/brands/brands/logos/000/000/045/main/m.png?1552252082",
    "cover_photo_url": "https://swyft-production.storage.googleapis.com/brands/brands/logos/000/000/045/main/m.png?1552252082",
    "name": "Maestro Pizza",
    "platform_id": 1,
  },
]

brands_attributes.each do |a|
  Brands::Brand.create(a)
end

stores_attributes = [
  {
    "id": 1,
    "brand_id": 1,
    "backend_id": 34907,
    "name_en": "Bash Manoush",
    "name_ar": "Bash Manoush",
    "latitude": 24.818389,
    "longitude": 46.642189,
  },
  {
    "id": 2,
    "backend_id": 460210,
    "brand_id": 2,
    "latitude": 18.251309,
    "longitude": 42.790272,
    "name": "166 Al Rasras,Khamis Mushait",
  },
  {
    "id": 3,
    "brand_id": 1,
    "backend_id": 3434,
    "name_en": "Bash Manoush store 2",
    "name_ar": "Bash Manoush",
    "latitude": 24.818389,
    "longitude": 46.642189,
  },
  {
    "id": 4,
    "backend_id": 4545656,
    "brand_id": 3,
    "latitude": 24.746356,
    "longitude": 46.618775,
    "name": "7 Nakheel",
  },
]

stores_attributes.each do |a|
  store = Stores::Store.create(a)
  Stores::StoreStatus.create(store_id: store.id, status: "ready")
end

catalogs_attributes = [
  {
    id: "a7b704f9-0c7e-4a6d-b8d7-65d14893265c",
    name: "Maestro Integration Menu",
    brand_id: 3,
    catalog_key: "1212fdd2-2667-4019-9f08-326cf6b2f427",
  },
]

catalogs_attributes.each do |a|
  Catalogs::Catalog.create(a)
end

catalog_assignments_attributes = [
  {
    catalog_id: "a7b704f9-0c7e-4a6d-b8d7-65d14893265c",
    related_to_type: "Brands::Brand",
    related_to_id: 3,
  },
]

catalog_assignments_attributes.each do |a|
  Catalogs::CatalogAssignment.create(a)
end

bash_account_attributes = {"name" => "Bash Manoush", "username" => "bash", "password" => "12345678"}
bash = Accounts::AccountService.new.create(bash_account_attributes)
Accounts::AccountService.new.grant_role(
  account_id: bash.id,
  role: "reception",
  role_resource_type: "Brands::Brand",
  role_resource_id: 1,
)
