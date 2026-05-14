class TasksController < ApplicationController
  include ProjectPolicy

  before_action :set_project_via_nested, only: %i[ new create ]
  before_action :set_task_and_project, only: %i[ show edit update destroy ]
  before_action :require_project_membership, only: %i[ show ]
  before_action :require_project_member_or_owner, only: %i[ new create edit update destroy ]

  def show
    respond_to do |format|
      format.html # renders show.html.erb (drawer turbo-frame in Plan 02-07)
    end
  end

  def new
    @task = @project.tasks.build(status: params[:status].presence_in(Task::STATUSES) || "backlog")
  end

  def create
    @task = @project.tasks.build(task_params)
    @task.creator = current_user
    @task.status = "backlog" unless Task::STATUSES.include?(@task.status)
    @task.priority ||= Task::PRIORITIES[:medium]
    @task.position = next_position_for(@task.project_id, @task.status)

    if @task.save
      respond_to do |format|
        format.html { redirect_to project_path(@project), notice: "Task created." }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      respond_to do |format|
        format.html { redirect_to task_path(@task), notice: "Task updated." }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    project = @task.project
    @task.destroy
    respond_to do |format|
      format.html { redirect_to project_path(project), notice: "Task deleted." }
      format.turbo_stream
    end
  end

  private
    def set_project_via_nested
      @project = Project.find_by!(slug: params[:project_slug])
    end

    def set_task_and_project
      @task = Task.find(params[:id])
      @project = @task.project
    end

    def task_params
      params.expect(task: [ :title, :description, :status, :priority, :due_date, :assignee_id ])
    end

    def next_position_for(project_id, status)
      (Task.where(project_id: project_id, status: status).maximum(:position) || -1) + 1
    end
end
