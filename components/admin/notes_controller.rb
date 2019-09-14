class Admin::NotesController < Admin::ApplicationController
  before_action :set_order, except: [:note_types]

  def index
    notes = Orders::Notes::NoteService.new.filter(criteria: {order_id: @order_dto&.id}, sort_direction: params[:sort_direction] || :desc)
    render json: {data: notes.map { |note| Admin::Presenters::Notes::Note.new(dto: note).present }}, status: :ok
  end

  def create
    return render json: {error: "Order Not found"}, status: :unprocessable_entity unless @order_dto
    author = Author.by_agent(entity: current_account_dto)
    note = Orders::Notes::NoteService.new(order: @order_dto, author: author).build_note(note_type: :agent, note: params[:note])
    if note.blank? || note.is_a?(String)
      return render json: {error: note || "Note Not found"}, status: :unprocessable_entity
    else
      return render json: Admin::Presenters::Notes::Note.new(dto: note).present, status: :ok
    end
  end

  def note_types
    note_types = Orders::Notes::NoteService.note_types
    render json: {status: true, data: note_types.map { |note_type| Admin::Presenters::Notes::NoteType.new(key: note_type).present }}
  end

  private

  def set_order
    @order_dto = Orders::OrderService.new.fetch(id: params[:order_id]) if params[:order_id].present?
  end
end
