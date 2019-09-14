class DTOCollection < Array
  attr_writer :total_count

  attr_writer :total_pages

  def total_count
    @total_count || length
  end

  def total_pages
    @total_pages || 1
  end
end
