class Admin::Presenters::Notes::Note
  def initialize(dto:)
    @note = dto
  end

  def present
    {
      "id": @note.id,
      "note_type": I18n.t("orders.note_types.#{@note.note_type}"),
      "note": @note.note,
      "author": author_presenter,
      "order_id": @note.order_id,
      "created_at": @note.created_at.to_i,
    }
  end

  private

  def author_presenter
    return {} unless @note.author
    author = @note.author
    {
      "category": author.category,
      "name": author.name,
      "type": author.category,
    }
  end
end
