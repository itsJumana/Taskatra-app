class MembershipsController < ApplicationController
  include ProjectPolicy

  before_action :set_project, only: %i[ index create ]
  before_action :set_membership_and_project, only: %i[ destroy ]
  before_action :require_project_membership, only: %i[ index ]
  before_action :require_project_owner, only: %i[ create destroy ]

  def index
    @memberships = @project.project_memberships.includes(:user).order(:role, :created_at)
  end

  def create
    email = params[:email].to_s.strip.downcase
    invitee = User.find_by(email_address: email)

    if invitee.nil?
      redirect_to project_memberships_path(@project),
                  alert: "No account found for that email."
      return
    end

    if @project.project_memberships.exists?(user: invitee)
      redirect_to project_memberships_path(@project),
                  alert: "#{invitee.email_address} is already a member."
      return
    end

    @project.project_memberships.create!(user: invitee, role: "member")
    redirect_to project_memberships_path(@project),
                notice: "#{invitee.email_address} added as member."
  end

  def destroy
    if @membership.role == "owner"
      redirect_to project_memberships_path(@project),
                  alert: "The project owner cannot be removed."
      return
    end

    user_email = @membership.user.email_address
    @membership.destroy
    redirect_to project_memberships_path(@project),
                notice: "#{user_email} removed from project."
  end

  private
    def set_project
      @project = Project.find_by!(slug: params[:project_slug])
    end

    def set_membership_and_project
      @membership = ProjectMembership.find(params[:id])
      @project = @membership.project
    end
end
