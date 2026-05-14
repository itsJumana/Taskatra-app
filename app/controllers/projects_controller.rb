class ProjectsController < ApplicationController
  include ProjectPolicy

  before_action :set_project, only: %i[ show edit update destroy ]
  before_action :require_project_membership, only: %i[ show ]
  before_action :require_project_owner, only: %i[ edit update destroy ]

  def index
    @projects = current_user.projects.includes(:owner).order(:name)
  end

  def show
    @tasks = @project.tasks.includes(:assignee).order(:position)
    @tasks_by_status = @tasks.group_by(&:status)
    @column_counts = Task::STATUSES.index_with { |s| (@tasks_by_status[s] || []).count }
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    @project.owner = current_user

    if @project.save
      redirect_to project_path(@project), notice: "Project created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to project_path(@project), notice: "Project updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project deleted."
  end

  private
    def set_project
      @project = current_user.projects.find_by!(slug: params[:slug])
    rescue ActiveRecord::RecordNotFound
      @project = Project.find_by(slug: params[:slug])
      raise ActiveRecord::RecordNotFound if @project.nil?
      # @project is set but user is not a member — let require_project_membership redirect
    end

    def project_params
      params.expect(project: [ :name, :description ])
    end
end
