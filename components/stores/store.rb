# == Schema Information
#
# Table name: stores
#
#  id             :bigint           not null, primary key
#  contact_name   :string
#  contact_number :string
#  deleted_at     :datetime
#  flags          :integer          default(0)
#  latitude       :decimal(10, 8)   not null
#  longitude      :decimal(11, 8)   not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  backend_id     :string
#  brand_id       :bigint           not null
#  city_id        :bigint
#  company_id     :uuid
#
# Indexes
#
#  index_stores_on_brand_id    (brand_id)
#  index_stores_on_city_id     (city_id)
#  index_stores_on_company_id  (company_id)
#  index_stores_on_deleted_at  (deleted_at)
#
# Foreign Keys
#
#  fk_rails_...  (brand_id => brands.id)
#

class Stores::Store < ApplicationRecord
  include FlagShihTzu

  belongs_to :brand, class_name: Brands::Brand.name
  belongs_to :company, class_name: Companies::Company.name, optional: true
  belongs_to :city, class_name: Cities::City.name, optional: true
  has_many :account_roles, class_name: Accounts::AccountRole.name, as: :role_resource
  has_many :orders, class_name: Orders::Order.name
  has_many :platform_stores, class_name: Stores::PlatformStore.name
  has_one :store_status, class_name: Stores::StoreStatus.name

  translates :name, touch: true, fallbacks_for_empty_translations: true
  translates :description, touch: true, fallbacks_for_empty_translations: true

  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name, :description]

  has_flags 1 => :approved,
            :column => "flags"

  scope :by_id, ->(id) { where(id: id) }
  scope :by_backend_id, ->(backend_id) { where(backend_id: backend_id) }
  scope :by_brand, ->(brand_id) { where(brand_id: brand_id) }
  scope :by_approval, ->(approval) { approval ? approved : not_approved }
  scope :by_company_id, ->(company_id) { where(company_id: company_id) }
  scope :with_status, ->(status) {
    joins(:store_status).where(store_statuses: {status: status})
  }
  scope :without_status, ->(status) {
    joins(:store_status).where.not(store_statuses: {status: status})
  }
  scope :by_similar_name, ->(similar_name) {
    joins(:translations, brand: :translations)
      .where("CONCAT(store_translations.name, ' ', brand_translations.name) ILIKE ?", "%#{similar_name}%").distinct
  }
  scope :by_similar_city_name, ->(similar_city_name) {
    joins(:city)
      .where("cities.name ILIKE ?", "%#{similar_city_name}%").distinct
  }

  scope :by_location_radius, ->(latitude, longitude, radius=20) {
    where("ST_Distance(ST_Point(#{table_name}.longitude, #{table_name}.latitude)::GEOGRAPHY, ST_Point(#{longitude.to_f}, #{latitude.to_f})::GEOGRAPHY) <= ?", (radius.to_f <= 0 ? 20 : radius.to_f))
  }

  enum delivery_type: DeliveryTypes::DeliveryType.key_ids

  after_soft_delete :mark_unapproved!
  validate :store_location

  def self.policy
    Stores::StorePolicy
  end

  private

  def mark_unapproved!
    Stores::Store.unscoped do
      update_instance = false
      update_flag!(:approved, 0, update_instance)
    end
  end

  def store_location
    return if brand.blank? || brand.country.blank? || brand.country.geom.blank?
    return if Countries::CountryService.new.valid_country?(id: brand.country_id, lat: latitude, lon: longitude)
    errors[:lat] << "is outside of brand's country"
  end
end
