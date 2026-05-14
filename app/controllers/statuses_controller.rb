class StatusesController < ApplicationController
  include ProjectPolicy

  before_action :set_task_and_project
  before_action :require_project_member_or_owner

  def update
    new_status = params[:status].to_s
    new_position = params[:position].to_i

    unless Task::STATUSES.include?(new_status)
      return render json: { error: "Invalid status" }, status: :unprocessable_entity
    end

    Task.transaction do
      @task.update!(status: new_status, position: new_position)
      rebalance_positions(@task.project_id, new_status)
    end

    render json: { ok: true, status: new_status, position: @task.reload.position }
  end

  private
    def set_task_and_project
      @task = Task.find(params[:task_id])
      @project = @task.project
    end

    def rebalance_positions(project_id, status)
      tasks = Task.where(project_id: project_id, status: status).order(:position, :id)
      tasks.each_with_index do |task, i|
        task.update_column(:position, i) if task.position != i
      end
    end
end
