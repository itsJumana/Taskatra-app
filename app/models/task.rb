class Task < ApplicationRecord
  STATUSES = %w[backlog todo in_progress in_review done cancelled].freeze
  PRIORITIES = { urgent: 0, high: 1, medium: 2, low: 3 }.freeze

  belongs_to :project
  belongs_to :creator, class_name: "User"
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :parent, class_name: "Task", optional: true
  has_many :subtasks, class_name: "Task", foreign_key: :parent_id, dependent: :destroy

  validates :title, presence: true, length: { maximum: 250 }
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES.values }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :in_status, ->(s) { where(status: s).order(:position) }

  def priority_name
    PRIORITIES.key(priority)
  end
end
