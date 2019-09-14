class Admin::Presenters::Notes::NoteType
  def initialize(key:)
    @key = key
  end

  def present
    return {} unless @key
    {
      "key": @key,
      "title": I18n.t("orders.note_types.#{@key}"),
    }
  end
end
