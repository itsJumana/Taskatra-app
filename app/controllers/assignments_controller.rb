class AssignmentsController < ApplicationController
  include ProjectPolicy

  before_action :set_task_and_project
  before_action :require_project_member_or_owner

  def update
    assignee_id = params[:assignee_id].presence

    if assignee_id && !@project.project_memberships.exists?(user_id: assignee_id)
      return render json: { error: "Assignee must be a project member" }, status: :unprocessable_entity
    end

    @task.update!(assignee_id: assignee_id)

    render json: { ok: true, assignee_id: @task.assignee_id }
  end

  private
    def set_task_and_project
      @task = Task.find(params[:task_id])
      @project = @task.project
    end
end
