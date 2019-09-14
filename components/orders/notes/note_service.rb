class Orders::Notes::NoteService
  include Common::Helpers::PaginationHelper
  def initialize(order: nil, author: nil)
    @order = order
    @author = author
  end

  def build_note(note_type:, note: nil)
    order_note = Orders::Notes::OrderNote.new(order_id: @order.id,
                                              author_category: @author.category, author_entity: @author.entity,
                                              note_type: note_type, note: note)
    if order_note.save
      return create_dto(order_note)
    end
    order_note.errors
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    notes = Orders::Notes::OrderNote.where(nil)
    notes = notes.by_order_id(criteria[:order_id]) if criteria[:order_id].present?
    notes = notes.by_note_type(criteria[:note_type]) if criteria[:note_type].present?
    notes = notes.order(sort_by => sort_direction) if sort_by
    paginated_dtos(collection: notes, page: page, per_page: per_page) do |note|
      create_dto(note)
    end
  end

  class << self
    def note_types
      Orders::Notes::OrderNote.note_types.keys
    end
  end

  private

  def create_dto(note)
    return unless note
    Orders::Notes::NoteDTO.new(
      id: note.id,
      order_id: note.order_id,
      note: note.note,
      note_type: note.note_type,
      created_at: note.created_at,
      author: Author.new(category: note.author_category, entity: note.author_entity)
    )
  end
end
