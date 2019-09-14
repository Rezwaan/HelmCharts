class Author
  include ActiveModel::Model

  validates :category, :entity, presence: true
  attr_accessor :category, :entity

  SYSTEM_ENTITY = ["platforms/swyft", "orders", "integration"]

  AGENT_ENTITY = {"Accounts::AccountDTO" => Accounts::AccountService}

  def initialize(category:, entity:)
    @category = category
    @entity = entity
  end

  def self.by_system(entity:)
    author = Author.new(category: "system", entity: entity) if entity.in? SYSTEM_ENTITY
    author
  end

  def self.by_agent(entity:)
    author = Author.new(category: entity.class.name, entity: entity.id) if entity.class.name.in? AGENT_ENTITY.keys
    author
  end

  def name
    author_name = "name unavailable"
    if @category.present?
      return @entity if @category == "system"
      entity = AGENT_ENTITY[@category].new.fetch(id: @entity) if AGENT_ENTITY[@category]
      return author_name if entity.blank?
      data = []
      data << entity.name if entity.respond_to?("name") && entity.name.present?
      data << "(#{entity.username})" if entity.respond_to?("username") && entity.username.present?
      data << "<#{entity.email}>" if entity.respond_to?("email") && entity.email.present?
      author_name = data.join(" ") if data.present?
    end
    author_name
  end
end
