class ProjectMembership < ApplicationRecord
  ROLES = %w[owner member viewer].freeze

  belongs_to :project
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :project_id }

  scope :owners, -> { where(role: "owner") }
  scope :members_or_owners, -> { where(role: %w[owner member]) }

  def owner?
    role == "owner"
  end

  def member?
    role == "member"
  end

  def viewer?
    role == "viewer"
  end
end
