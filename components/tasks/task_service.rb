class Tasks::TaskService
  include Common::Helpers::PaginationHelper

  def initialize
  end

  def create(task_type:, related_to_type:, related_to_id:, expiry: nil, store_id:)
    task = Tasks::Task.new(
      task_type: task_type,
      related_to_type: related_to_type,
      related_to_id: related_to_id,
      store_id: store_id
    )
    unless expiry.nil?
      task.expiry_at = Time.now + expiry
    end

    if task.save
      create_dto(task)
    else
      task.errors
    end
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    tasks = Tasks::Task.includes(store: :translations).where(nil)
    tasks = tasks.by_id(criteria[:id]) if criteria[:id].present?
    tasks = tasks.by_store(criteria[:store_id]) if criteria[:store_id].present?
    tasks = tasks.by_status(criteria[:status]) if criteria[:status].present?
    tasks = tasks.order(sort_by => sort_direction) if sort_by

    paginated_dtos(collection: tasks, page: page, per_page: per_page) do |task|
      create_dto(task)
    end
  end

  def complete(id:)
    task = Tasks::Task.find(id)
    task.update(status: "completed")
    create_dto(task)
  end

  private

  def create_dto(task)
    Tasks::TaskDTO.new({
      id: task.id,
      task_type: task.task_type,
      status: task.status,
      title: "Task Title",
      description: "Task Description",
      related_to_type: task.related_to_type,
      related_to_id: task.related_to_id,
      related_to: Orders::OrderService.new.fetch_light(id: task.related_to_id), # @TODO Support polymorphic
      expiry_at: task.expiry_at,
      store: Stores::StoreService.new.create_light_dto(task.store),
      operations: [:complete],
    })
  end
end
