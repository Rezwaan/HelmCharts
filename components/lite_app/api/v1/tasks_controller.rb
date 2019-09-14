class LiteApp::Api::V1::TasksController < LiteApp::Api::V1::ApplicationController
  def index
    criteria = {store_id: account_store_ids, status: "created"}
    @tasks = Tasks::TaskService.new.filter(criteria: criteria, per_page: 100, sort_direction: "desc")

    render json: {
      status: true,
      total_records: @tasks.total_count,
      total_pages: @tasks.total_pages,
      data: @tasks,
    }
  end

  def show
    criteria = {store_id: account_store_ids, status: "created", id: params[:id]}
    @task = Tasks::TaskService.new.filter(criteria: criteria, per_page: 1).first

    render json: @task
  end

  def perform
    criteria = {store_id: account_store_ids, status: "created", id: params[:id]}
    @task = Tasks::TaskService.new.filter(criteria: criteria, per_page: 1).first
    return head :not_found if @task.nil?

    action = params["operation"]

    return head :unprocessable_entity unless action == "complete"

    @task = Tasks::TaskService.new.complete(id: params[:id])

    render json: @task
  end
end
