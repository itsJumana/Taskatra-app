module ProjectPolicy
  extend ActiveSupport::Concern

  included do
    helper_method :current_membership, :project_owner?, :project_member?, :project_viewer?
  end

  private
    def current_membership
      return nil unless @project && current_user

      @current_membership ||= @project.project_memberships.find_by(user: current_user)
    end

    def require_project_membership
      return if current_membership

      redirect_to projects_path, alert: "You are not a member of this project."
    end

    def require_project_owner
      return if current_membership&.role == "owner"

      redirect_to project_path(@project), alert: "Only the project owner can do that."
    end

    def require_project_member_or_owner
      return if %w[owner member].include?(current_membership&.role)

      redirect_to project_path(@project), alert: "You don't have permission to do that."
    end

    def project_owner?
      current_membership&.role == "owner"
    end

    def project_member?
      current_membership&.role == "member"
    end

    def project_viewer?
      current_membership&.role == "viewer"
    end
end
