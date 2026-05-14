class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :project_memberships, dependent: :destroy
  has_many :projects, through: :project_memberships
  has_many :owned_projects, class_name: "Project", foreign_key: :owner_id, dependent: :destroy
  has_many :created_tasks, class_name: "Task", foreign_key: :creator_id, dependent: :destroy
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assignee_id, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
