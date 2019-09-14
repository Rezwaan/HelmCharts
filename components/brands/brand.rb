# == Schema Information
#
# Table name: brands
#
#  id                :bigint           not null, primary key
#  cover_photo_url   :string
#  flags             :integer          default(0), not null
#  logo_url          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  backend_id        :string
#  brand_category_id :bigint
#  company_id        :uuid
#  country_id        :bigint
#  platform_id       :bigint
#
# Indexes
#
#  index_brands_on_brand_category_id  (brand_category_id)
#  index_brands_on_company_id         (company_id)
#  index_brands_on_country_id         (country_id)
#  index_brands_on_platform_id        (platform_id)
#
# Foreign Keys
#
#  fk_rails_...  (brand_category_id => brand_categories.id)
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (platform_id => platforms.id)
#

class Brands::Brand < ApplicationRecord
  include FlagShihTzu

  belongs_to :platform, class_name: Platforms::Platform.name, optional: true
  belongs_to :company, class_name: Companies::Company.name, optional: true
  belongs_to :country, class_name: Countries::Country.name, optional: true
  # TODO: UPDATE ONCE ALL DATA IMPORTED
  belongs_to :brand_category, class_name: Brands::Categories::BrandCategory.name, optional: true
  has_many :brand_brand_categories, class_name: Brands::Categories::BrandBrandCategory.name
  has_many :brand_categories, through: :brand_brand_categories
  has_many :account_roles, class_name: Accounts::AccountRole.name, as: :role_resource
  has_many :catalog, class_name: Catalogs::Catalog.name

  translates :name, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name]

  validates :cover_photo_url, :logo_url, presence: true, allow_blank: false

  has_flags 1 => :contracted,
            2 => :approved,
            :column => "flags"

  scope :by_id, ->(id) { where(id: id) }
  scope :by_country_id, ->(country_id) { where(country_id: country_id) }
  scope :by_company_id, ->(company_id) { where(company_id: company_id) }
  scope :by_backend_id, ->(backend_id) { where(backend_id: backend_id) }
  scope :by_similar_name, ->(similar_name) {
    joins(:translations).where("brand_translations.name ILIKE ?", "%#{similar_name}%").distinct
  }

  def self.policy_class
    Brands::BrandPolicy
  end
end
