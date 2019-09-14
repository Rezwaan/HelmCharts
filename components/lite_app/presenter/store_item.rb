class LiteApp::Presenter::StoreItem
  def initialize(dto:)
    @dto = dto
  end

  def present
    {
      id: @dto.id,
      catalog_id: @dto.catalog_id,
      store_id: @dto.store_id,
      item_id: @dto.item_id,
      expiry_at: @dto.expiry_at,
    }
  end
end
